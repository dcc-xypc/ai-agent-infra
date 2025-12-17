output "web_frontend_app_name" {
  description = "Cloud Runサービスの名前です（web-frontend-app）。"
  value       = google_cloud_run_v2_service.web_frontend_app.name
}

output "web_frontend_app_url" {
  description = "Cloud Runサービスの公開URLです（web-frontend-app）。"
  value       = google_cloud_run_v2_service.web_frontend_app.uri
}

output "web_backend_app_name" {
  description = "Cloud Runサービスの名前です（web-backend-app）。"
  value       = google_cloud_run_v2_service.web_backend_app.name
}

output "web_backend_app_url" {
  description = "Cloud Runサービスの公開URLです（web-backend-app）。"
  value       = google_cloud_run_v2_service.web_backend_app.uri
}

output "auth_keycloak_app_name" {
  description = "Cloud Runサービスの名前です（auth-keycloak-app）。"
  value       = google_cloud_run_v2_service.auth_keycloak_app.name
}

output "auth_keycloak_app_url" {
  description = "Cloud Runサービスの公開URLです（auth-keycloak-app）。"
  value       = google_cloud_run_v2_service.auth_keycloak_app.uri
}

output "oauth2_proxy_app_name" {
  description = "Cloud Runサービスの名前です（auth-keycloak-app）。"
  value       = google_cloud_run_v2_service.oauth2_proxy_app.name
}

output "oauth2_proxy_app_url" {
  description = "Cloud Runサービスの公開URLです（auth-keycloak-app）。"
  value       = google_cloud_run_v2_service.oauth2_proxy_app.uri
}
