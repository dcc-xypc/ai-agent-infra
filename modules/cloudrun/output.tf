output "web_frontend_app_name" {
  description = "Cloud Runサービスの名前です。"
  value       = google_cloud_run_v2_service.web_frontend_app.name
}

output "web_frontend_app_url" {
  description = "Cloud Runサービスの公開URLです。"
  value       = google_cloud_run_v2_service.web_frontend_app.uri
}

output "web_backend_app_name" {
  description = "Cloud Runサービスの名前です。"
  value       = google_cloud_run_v2_service.web_backend_app.name
}

output "web_frontend_app_url" {
  description = "Cloud Runサービスの公開URLです。"
  value       = google_cloud_run_v2_service.web_backend_app.uri
}

output "auth_keycloak_app_name" {
  description = "Cloud Runサービスの名前です。"
  value       = google_cloud_run_v2_service.auth_keycloak_app.name
}

output "auth_keycloak_app_url" {
  description = "Cloud Runサービスの公開URLです。"
  value       = google_cloud_run_v2_service.auth_keycloak_app.uri
}
