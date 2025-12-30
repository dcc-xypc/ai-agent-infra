output "web_frontend_app_name" {
  value       = google_cloud_run_v2_service.web_frontend_app.name
  description = "Frontend Cloud Run サービスの名前"
}

output "web_frontend_app_url" {
  value       = google_cloud_run_v2_service.web_frontend_app.uri
  description = "Frontend Cloud Run サービスの URI"
}

output "web_backend_app_name" {
  value       = google_cloud_run_v2_service.web_backend_app.name
  description = "Backend Cloud Run サービスの名前"
}

output "web_backend_app_url" {
  value       = google_cloud_run_v2_service.web_backend_app.uri
  description = "Backend Cloud Run サービスの URI"
}

output "auth_keycloak_app_name" {
  value       = google_cloud_run_v2_service.auth_keycloak_app.name
  description = "Keycloak Cloud Run サービスの名前"
}

output "auth_keycloak_app_url" {
  value       = google_cloud_run_v2_service.auth_keycloak_app.uri
  description = "Keycloak Cloud Run サービスの URI"
}

output "oauth2_proxy_app_name" {
  value       = google_cloud_run_v2_service.oauth2_proxy_app.name
  description = "OAuth2 Proxy Cloud Run サービスの名前"
}

output "oauth2_proxy_app_url" {
  value       = google_cloud_run_v2_service.oauth2_proxy_app.uri
  description = "OAuth2 Proxy Cloud Run サービスの URI"
}