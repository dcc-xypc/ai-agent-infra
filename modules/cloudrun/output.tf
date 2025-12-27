output "web_frontend_app_name" {
  value       = google_cloud_run_v2_service.web_frontend_app.name
  description = "Cloud Runサービスの名前です（web-frontend-app）"
}

output "web_frontend_app_url" {
  value       = google_cloud_run_v2_service.web_frontend_app.uri
  description = "Cloud Runサービスの公開URLです（web-frontend-app）"
}

output "web_backend_app_name" {
  value       = google_cloud_run_v2_service.web_backend_app.name
  description = "Cloud Runサービスの名前です（web-backend-app）"
}

output "web_backend_app_url" {
  value       = google_cloud_run_v2_service.web_backend_app.uri
  description = "Cloud Runサービスの公開URLです（web-backend-app）"
}

output "auth_keycloak_app_name" {
  value       = google_cloud_run_v2_service.auth_keycloak_app.name
  description = "Cloud Runサービスの名前です（auth-keycloak-app）"
}

output "auth_keycloak_app_url" {
  value       = google_cloud_run_v2_service.auth_keycloak_app.uri
  description = "Cloud Runサービスの公開URLです（auth-keycloak-app）"
}

output "oauth2_proxy_app_name" {
  value       = var.setup_keycloak_resources ? google_cloud_run_v2_service.oauth2_proxy_app[0].name : ""
  description = "Cloud Runサービスの名前です（oauth2-proxy-app）"
}

output "oauth2_proxy_app_url" {
  value       = var.setup_keycloak_resources ? google_cloud_run_v2_service.oauth2_proxy_app[0].uri : ""
  description = "Cloud Runサービスの公開URLです（oauth2-proxy-app）"
}
