output "load_balancer_ip" {
  description = "ロードバランサーの静的 IP アドレスです。"
  value       = google_compute_global_address.lb_ip.address
}

output "internal_lb_ip" {
  description = "The internal IP address of the Internal ALB"
  value       = google_compute_forwarding_rule.internal_rule.ip_address
}
