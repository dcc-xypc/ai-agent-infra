# -----------------------------------------------------------------
# 1. 前端 Web 应用: web-frontend-app (对外公开, 无 DB)
# -----------------------------------------------------------------
resource "google_cloud_run_v2_service" "web_frontend_app" {
  name     = "web-frontend-app-${var.env_name}"
  location = var.region
  project  = var.project_id

  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = var.external_cloudrun_sa_email
    session_affinity = true
    
    containers {
      image = var.default_placeholder_image
    }
    
    vpc_access {
      connector = var.connector_id
      egress    = "ALL_TRAFFIC"
    }
  }
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
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
    
  ingress  = "INGRESS_TRAFFIC_ALL"

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
        value_source {
          secret_key_ref {
            secret  = "ai_agent_db_password"
            version = "latest"
          }
        }
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
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
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

  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

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
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
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

  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = var.external_cloudrun_sa_email
    session_affinity = true 
    scaling {
      min_instance_count = 1
      max_instance_count = 2
    }
    
    containers {
      image = "gcr.io/q14020-d-toyota-imap-dev/auth-keycloak-app:d0a0e2e"
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
      
      env {
        name  = "ENVIRONMENT" 
        value = "GCP"
      }
      env {
        name  = "LOGGING_CONSOLE" 
        value = "true"
      }
      env {
        name  = "KC_DB" 
        value = "postgres"
      }
      env {
        name  = "KC_DB_URL"
        value = "jdbc:postgresql:///${var.keycloak_db_name}?cloudSqlInstance=${var.keycloak_db_connection_name}&socketFactory=com.google.cloud.sql.postgres.SocketFactory"
      }
      env {
        name  = "KC_DB_USERNAME" 
        value = var.keycloak_db_user
      }
      env {
        name  = "KC_DB_PASSWORD" 
        value_source {
          secret_key_ref {
            secret  = "keycloak_db_password"
            version = "latest"
          }
        }
      }
      env { 
        name  = "KC_BOOTSTRAP_ADMIN_USERNAME" 
        value = var.keycloak_admin_name
      }
      env { 
        name  = "KC_BOOTSTRAP_ADMIN_PASSWORD" 
        value_source {
          secret_key_ref {
            secret  = "keycloak_admin_password"
            version = "latest"
          }
        }
      }
      env { 
        name  = "KC_HOSTNAME" 
        value = var.auth_domain
      }
      env { 
        name  = "KC_HOSTNAME_URL" 
        value = "https://${var.auth_domain}"
      }
      env { 
        name  = "KC_HOSTNAME_STRICT_HTTPS" 
        value = "true"
      }
      env { 
        name  = "KC_CACHE_STACK" 
        value = "jdbc-ping"
      }
      env { 
        name  = "KC_BIND_ADDRESS" 
        value = "0.0.0.0"
      }
      env {
        name  = "KC_HTTP_ENABLED"
        value = "true"
      }
      env {
        name  = "KC_HTTP_PORT"
        value = "8080"
      }
      env {
        name  = "KC_PROXY"
        value = "edge"
      }
      env {
        name  = "KC_PROXY_HEADERS"
        value = "forwarded"
      }

      # 数据库与事务配置
      env {
        name  = "KC_TRANSACTION_MODE"
        value = "non-xa"
      }
      env {
        name  = "KC_TRANSACTION_XA_ENABLED"
        value = "false"
      }
      env {
        name  = "KC_DB_DIALECT"
        value = "org.hibernate.dialect.PostgreSQLDialect"
      }
      env {
        name  = "KC_DB_DRIVER"
        value = "org.postgresql.Driver"
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "2Gi" # Keycloak 启动较重，建议至少 2Gi
        }
      }
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [var.keycloak_db_connection_name]
      }
    } 
    vpc_access {
      connector = var.connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
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
  # 如果变量 oauth2_proxy_image_gcr 为空，则使用拼接后的默认值
  target_proxy_image = var.oauth2_proxy_image_gcr != "" ? var.oauth2_proxy_image_gcr : "gcr.io/${var.project_id}/oauth2-proxy:v7.13.0"
}

resource "google_cloud_run_v2_service" "oauth2_proxy_app" {
  name     = "oauth2-proxy-app-${var.env_name}"
  location = var.region
  project  = var.project_id
  
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  depends_on = [
    google_cloud_run_v2_service.web_backend_app
  ]

  template {
    service_account = var.external_cloudrun_sa_email
    session_affinity = true
    
    containers {
      image = local.target_proxy_image
      # image = var.default_placeholder_image
      
      env {
        name  = "OAUTH2_PROXY_HTTP_ADDRESS"
        value = "0.0.0.0:8080" 
      }
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
      env {
        name  = "OAUTH2_PROXY_EMAIL_DOMAINS"
        value = "*" 
      }
      env {
        name  = "OAUTH2_PROXY_WHITELIST_DOMAINS"
        value = ".ai-agent.tcic-cloud.com" # 允许以该后缀结尾的所有域名跳转
      }
      env {
        name  = "OAUTH2_PROXY_SET_XAUTHREQUEST"
        value = "true"
      }
      env {
        name  = "OAUTH2_PROXY_SKIP_AUTH_PREFLIGHT"
        value = "true"
      }
      # 目标后端是 web-backend-app 的内部 URL
      env {
        name  = "OAUTH2_PROXY_UPSTREAMS"
        value = "${google_cloud_run_v2_service.web_backend_app.uri}/"
      }
      env {
        name  = "OAUTH2_PROXY_PASS_HOST_HEADER"
        value = "false" # 必须设为 false，让 Proxy 使用 Upstream 的 Host
      }
      env {
        name  = "OAUTH2_PROXY_INSECURE_OIDC_ALLOW_UNVERIFIED_EMAIL"
        value = "true" # 允许未验证邮箱的用户登录，避免再次触发 500
      }
      env { 
        name  = "OAUTH2_PROXY_PROVIDER" 
        value = "oidc" 
      }
      env {
        name  = "OAUTH2_PROXY_OIDC_ISSUER_URL"
        value = "${var.keycloak_external_url}/realms/ai-agent-realm" 
      }
      env {
        name  = "OAUTH2_PROXY_REDIRECT_URL"
        value = "https://${var.tenant_domain}/oauth2/callback"
      }
      # 1. 解决 403 问题：跳过 Proxy 默认登录页，强制重定向到 Keycloak
      env {
        name  = "OAUTH2_PROXY_SKIP_PROVIDER_BUTTON"
        value = "true"
      }

      # 2. 允许对 API 路径进行重定向（关键修复）
      # 这会防止 Proxy 对 ajax/api 请求默认返回 403
      env {
        name  = "OAUTH2_PROXY_REVERSE_PROXY"
        value = "true"
      }

      # 3. 设置 Cookie 作用域，确保在整个租户域名下有效
      #env {
      #  name  = "OAUTH2_PROXY_COOKIE_DOMAINS"
      #  value = var.tenant_domain
      #}
      env {
        name  = "OAUTH2_PROXY_COOKIE_PATH"
        value = "/"
      }
      env {
        name  = "OAUTH2_PROXY_SSL_INSECURE_SKIP_VERIFY"
        value = "true"  # 1. 强制跳过对 ALB 证书的 SSL 验证 
      }
      env {
        name  = "OAUTH2_PROXY_PASS_ACCESS_TOKEN"
        value = "true"
      }
      env {
        name  = "OAUTH2_PROXY_PASS_AUTHORIZATION_HEADER"
        value = "true"
      }
      env {
        name  = "OAUTH2_PROXY_COOKIE_SAMESITE"
        value = "lax" # 允许从前端页面发起的同域名 API 请求携带 Cookie
      }
      env {
        name  = "OAUTH2_PROXY_COOKIE_CSRF_PER_REQUEST"
        value = "false" # 针对 API 场景关闭逐请求 CSRF，防止 403
      }
      env {
        name  = "OAUTH2_PROXY_INSECURE_OIDC_SKIP_ISSUER_VERIFICATION"
        value = "true"  # 2. 跳过 OIDC 发行者 URL 的严格匹配校验 
      }
      env {
        name  = "OAUTH2_PROXY_COOKIE_SECURE"
        value = "true"  # 3. 确保在 HTTPS (ALB) 环境下 Cookie 能正常工作 
      }
      env {
        name  = "OAUTH2_PROXY_ERRORS_TO_INFO_LOG"
        value = "true"
      }
    }
    
    vpc_access {
      connector = var.connector_id
      egress    = "PRIVATE_RANGES_ONLY"
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
