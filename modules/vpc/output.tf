output "vpc_id" {
  value       = google_compute_network.vpc_network.id
  description = "VPC 网络的唯一标识符 (self_link)。"
}

output "network_self_link" {
  description = "作成されたVPCネットワークのセルフリンクです。"
  value       = google_compute_network.vpc_network.self_link
}

output "connector_id" {
  description = "VPCアクセスコネクタのセルフリンクです。"
  value       = google_vpc_access_connector.main_connector.id
}

output "ops_subnet_id" {
  description = "运维管理专用子网 ID，用于部署维护机（Ops VM）。"
  value       = google_compute_subnetwork.ops_subnet.id
}

