output "cloud_sql_instance_name" {
  description = "Cloud SQLインスタンスの接続名です。"
  value       = module.cloudsql.instance_connection_name
}

output "app_service_url" {
  description = "Cloud Runサービスの公開URLです。"
  value       = module.cloudrun.app_service_url
}

output "load_balancer_ip" {
  description = "外部アプリケーションロードバランサーの予約されたIPアドレスです。"
  value       = module.loadbalancer.load_balancer_ip
}
