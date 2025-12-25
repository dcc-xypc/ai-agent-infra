output "load_balancer_ip" {
  description = "ロードバランサーの静的 IP アドレスです。"
  value       = google_compute_global_address.lb_ip.address
}
# 输出后端服务的名称，用于 auth 模块绑定 IAP IAM 权限
output "web_backend_service_name" {
  description = "The name of the backend service for IAP binding"
  # 请确保这里的名称与你 loadbalancer/main.tf 中定义 google_compute_backend_service 的资源名一致
  value       = google_compute_backend_service.backend_backend.name 
}
