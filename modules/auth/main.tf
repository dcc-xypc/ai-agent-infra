terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.0"
    }
  }
}
# 获取项目编号用于构建 IAP 系统账号
data "google_project" "project" {}

# 1. 启用 Identity Platform
resource "google_identity_platform_config" "default" {
  provider      = google-beta
  project       = var.project_id
}

# 2. 将 Keycloak 配置为 OIDC 提供方
resource "google_identity_platform_oidc_config" "keycloak_idp" {
  provider      = google-beta
  project       = var.project_id
  name          = "oidc.keycloak"
  display_name  = "Keycloak Login"
  client_id     = var.oauth2_proxy_client_id
  client_secret = var.oauth2_proxy_client_secret
  issuer        = var.keycloak_external_url
  enabled       = true
  depends_on    = [google_identity_platform_config.default]
}

# 3. IAP 访问权限：允许通过 Keycloak 登录的用户访问 LB 后端
resource "google_iap_web_backend_service_iam_member" "iap_access" {
  project             = var.project_id
  web_backend_service = var.web_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "allAuthenticatedUsers" 
}

# 4. IAP 调用权限：允许 IAP 服务账号调用后端 Cloud Run
resource "google_cloud_run_v2_service_iam_member" "iap_to_run" {
  project  = var.project_id
  location = var.region
  name     = var.web_backend_app_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
}
