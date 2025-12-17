output "cloud_sql_instance_name" {
  description = "Cloud SQLインスタンスの接続名です。"
  value       = module.cloudsql.instance_connection_name
}

output "web_frontend_app_url" {
  description = "Cloud Runサービスの公開URLです。"
  value       = module.cloudrun.web_frontend_app_url
}

output "load_balancer_ip" {
  description = "外部アプリケーションロードバランサーの予約されたIPアドレスです。"
  value       = module.loadbalancer.load_balancer_ip
}
