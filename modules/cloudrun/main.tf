# -----------------------------------------------------------------
# 1. 前端 Web 应用: web-frontend-app (对外公开, 无 DB)
# -----------------------------------------------------------------
resource "google_cloud_run_v2_service" "web_frontend_app" {
  name     = "web-frontend-app-${var.env_name}"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.external_cloudrun_sa_email
    
    containers {
      image = var.default_placeholder_image
    }
    
    vpc_access {
      connector = var.connector_id
      egress    = "ALL_TRAFFIC"
    }
  }
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "web_frontend_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.web_frontend_app.name
  role     = "roles/run.invoker"
  member   = "allUsers" 
}

# -----------------------------------------------------------------
# 2. Web 后端应用: web-backend-app (内部服务, 连接 AI Agent DB, 被 Proxy 保护)
# -----------------------------------------------------------------
resource "google_cloud_run_v2_service" "web_backend_app" {
  name     = "web-backend-app-${var.env_name}"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.external_cloudrun_sa_email
    
    containers {
      image = var.default_placeholder_image
      
      # 数据库连接配置 (AI Agent DB)
      env {
        name  = "CLOUD_SQL_CONN_NAME"
        value = var.ai_agent_db_connection_name 
      }
      env {
        name  = "DB_NAME"
        value = var.ai_agent_db_name
      }
      env {
        name  = "DB_USER"
        value = var.ai_agent_db_user
      }
      env {
        name  = "DB_PASSWORD"
        value = var.ai_agent_db_password
      }
      # 内部服务调用 URL
      env {
        name  = "AI_AGENT_URL"
        value = google_cloud_run_v2_service.ai_agent_engine_app.uri
      }
    }
    
    vpc_access {
      connector = var.connector_id
      egress    = "ALL_TRAFFIC"
    }
  }
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# 2.1 后端 Invoker 权限 (仅允许 OAuth2 Proxy)
resource "google_cloud_run_v2_service_iam_member" "web_backend_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.web_backend_app.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.external_cloudrun_sa_email}" 
}

# -----------------------------------------------------------------
# 3. AI Agent 服务: ai-agent-engine-app (内部服务, 无 DB)
# -----------------------------------------------------------------
resource "google_cloud_run_v2_service" "ai_agent_engine_app" {
  name     = "ai-agent-engine-app-${var.env_name}"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.external_cloudrun_sa_email
    
    containers {
      image = var.default_placeholder_image
    }
    
    vpc_access {
      connector = var.connector_id
      egress    = "ALL_TRAFFIC"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# 3.1 AI Agent 权限 (仅允许后端服务调用)
resource "google_cloud_run_v2_service_iam_member" "ai_agent_engine_backend_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.ai_agent_engine_app.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.external_cloudrun_sa_email}" 
}

# -----------------------------------------------------------------
# 4. Keycloak 认证服务: auth-keycloak-app (对外公开, 连接 Keycloak DB)
# -----------------------------------------------------------------
resource "google_cloud_run_v2_service" "auth_keycloak_app" {
  name     = "auth-keycloak-app-${var.env_name}"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.external_cloudrun_sa_email
    
    containers {
      image = var.default_placeholder_image
      
      env {
        name  = "CLOUD_SQL_CONN_NAME"
        value = var.keycloak_db_connection_name 
      }
      env {
        name  = "KC_DB_DATABASE"
        value = var.keycloak_db_name
      }
      env {
        name  = "KC_DB_USERNAME"
        value = var.keycloak_db_user
      }
      env {
        name  = "KC_DB_PASSWORD"
        value = var.keycloak_db_password
      }
      
      # Keycloak 启动配置 - 修正为严格格式
      env {
        name  = "KC_DB" 
        value = "postgres"
      }
      env { 
        name  = "KEYCLOAK_ADMIN" 
        value = var.keycloak_admin_name
      }
      env { 
        name  = "KEYCLOAK_ADMIN_PASSWORD" 
        value = var.keycloak_admin_password 
      }
      # ⚠️ 注意：您可能还需要设置 KC_HOSTNAME_URL 等变量
    }
    
    vpc_access {
      connector = var.connector_id
      egress    = "ALL_TRAFFIC"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "auth_keycloak_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.auth_keycloak_app.name
  role     = "roles/run.invoker"
  member   = "allUsers" 
}

# -----------------------------------------------------------------
# 5. OAuth2 Proxy 服务: oauth2-proxy-app (代理后端认证)
# -----------------------------------------------------------------
locals {
  # 如果变量 target_oauth_proxy_image 为空，则使用拼接后的默认值
  # 这样既保留了灵活性，又解决了报错
  target_proxy_image = var.target_oauth2_proxy_image != "" ? var.target_oauth2_proxy_image : "gcr.io/${var.project_id}/oauth2-proxy:v7.13.0"
}

resource "null_resource" "mirror_proxy_image" {
  triggers = {
    source_tag = var.oauth2_proxy_image
    target_tag = var.target_proxy_image
  }

  provisioner "local-exec" {
    command = <<EOT
      docker pull ${var.oauth2_proxy_image}
      docker tag ${var.oauth2_proxy_image} ${var.target_proxy_image}
      docker push ${var.target_proxy_image}
    EOT
  }
}

resource "google_cloud_run_v2_service" "oauth2_proxy_app" {
  name     = "oauth2-proxy-app-${var.env_name}"
  location = var.region
  project  = var.project_id
  
  depends_on = [google_cloud_run_v2_service.web_backend_app] 

  template {
    service_account = var.external_cloudrun_sa_email
    
    containers {
      image = var.target_proxy_image
      
      # 修正为严格格式
      env { 
        name  = "OAUTH2_PROXY_CLIENT_ID" 
        value = var.oauth2_proxy_client_id 
      }
      env { 
        name  = "OAUTH2_PROXY_CLIENT_SECRET" 
        value = var.oauth2_proxy_client_secret 
      }
      env { 
        name  = "OAUTH2_PROXY_COOKIE_SECRET" 
        value = var.oauth2_proxy_cookie_secret 
      }
      
      # 目标后端是 web-backend-app 的内部 URL
      env {
        name  = "OAUTH2_PROXY_UPSTREAMS"
        value = google_cloud_run_v2_service.web_backend_app.uri
      }
      
      # Keycloak OIDC 配置 - 修正为严格格式
      env { 
        name  = "OAUTH2_PROXY_PROVIDER" 
        value = "oidc" 
      }
      env {
        name  = "OAUTH2_PROXY_OIDC_ISSUER_URL"
        # ⚠️ 替换为您的实际 Realm URL
        value = "${var.keycloak_external_url}/realms/my-realm" 
      }
    }
    
    vpc_access {
      connector = var.connector_id
      egress    = "ALL_TRAFFIC"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "oauth2_proxy_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.oauth2_proxy_app.name
  role     = "roles/run.invoker"
  member   = "allUsers" 
}
