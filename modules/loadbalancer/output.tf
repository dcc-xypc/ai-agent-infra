output "load_balancer_ip" {
  description = "ロードバランサーの静的 IP アドレスです。"
  value       = google_compute_global_address.lb_ip.address
}
