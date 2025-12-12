output "service_name" {
  description = "Cloud Runサービスの名前です。"
  value       = google_cloud_run_v2_service.app_service.name
}

output "app_service_url" {
  description = "Cloud Runサービスの公開URLです。"
  value       = google_cloud_run_v2_service.app_service.uri
}
