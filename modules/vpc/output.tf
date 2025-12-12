output "network_self_link" {
  description = "作成されたVPCネットワークのセルフリンクです。"
  value       = google_compute_network.vpc_network.self_link
}

output "connector_id" {
  description = "VPCアクセスコネクタのセルフリンクです。"
  value       = google_vpc_access_connector.main_connector.id
}
