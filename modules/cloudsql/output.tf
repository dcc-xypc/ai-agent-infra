output "instance_connection_name" {
  description = "Cloud SQLインスタンスの接続名です。"
  value       = google_sql_database_instance.postgres_instance.connection_name
}
