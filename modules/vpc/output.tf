output "vpc_id" {
  value       = google_compute_network.vpc_network.id
  description = "VPCネットワークの唯一識別子 (ID)"
}

output "network_self_link" {
  value       = google_compute_network.vpc_network.self_link
  description = "作成されたVPCネットワークのセルフリンク"
}

output "lb_ip_address" {
  value = google_compute_global_address.lb_static_ip.address
}

output "nat_ip_address" {
  value = google_compute_address.nat_static_ip.address
}

output "ilb_subnet_id" {
  value       = google_compute_subnetwork.ilb_subnet.id
  description = "アプリケーションサブネットのID"
}

output "ops_subnet_id" {
  value       = google_compute_subnetwork.ops_subnet.id
  description = "OpsサブネットのID（Ops VMデプロイ用）"
}

output "connector_subnet_id" {
  value       = google_compute_subnetwork.connector_subnet.id
  description = "CloudサブネットのID"
}

output "nat_status" {
  value       = var.enable_ops_nat ? google_compute_router_nat.nat[0].id : ""
  description = "NATのステータス"
}

output "internal_lb_ip_address" {
  value       = google_compute_address.internal_lb_static_ip.address
  description = "Internal ALB用の静的内部IPアドレス"
}

