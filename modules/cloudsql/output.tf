output "instance_connection_name" {
  description = "Cloud SQLインスタンスの接続名です。"
  value       = google_sql_database_instance.postgres_instance.connection_name
}

output "ai_agent_database_name" {
  description = "The name of the AI Agent application database."
  value       = google_sql_database.ai_agent_db.name
}

output "keycloak_database_name" {
  description = "The name of the Keycloak authentication database."
  value       = google_sql_database.keycloak_db.name
}

output "cloud_sql_connection_name" {
  description = "The connection name for the Cloud SQL instance (e.g., project:region:instance)."
  value       = google_sql_database_instance.postgres_instance.connection_name
}
