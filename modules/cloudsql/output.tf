# modules/cloudsql/output.tf

# ----------------------------------------------------
# 1. Cloud SQL インスタンス接続名 (CLOUD_SQL_CONN_NAME)
# ----------------------------------------------------
output "instance_connection_name" {
  value       = google_sql_database_instance.postgres_instance.connection_name
  description = "Cloud SQLインスタンスの接続名で、Cloud Runによって使用されます"
}

output "mysql_instance_connection_name" {
  value       = google_sql_database_instance.mysql_instance.connection_name
  description = "MySQL Cloud SQLインスタンスの接続名で、Cloud Runによって使用されます"
}

# ----------------------------------------------------
# 2. AI Agent データベース接続情報 (web-backend-app 用)
# ----------------------------------------------------
output "ai_agent_db_name" {
  value       = google_sql_database.ai_agent_db.name
  description = "AI Agentアプリケーションのデータベース名"
}

output "ai_agent_user_name" {
  value       = google_sql_user.ai_agent_user.name
  description = "AI Agentデータベース接続のユーザー名"
}

# ----------------------------------------------------
# 3. Keycloak データベース接続情報 (auth-keycloak-app 用)
# ----------------------------------------------------
output "keycloak_db_name" {
  value       = google_sql_database.keycloak_db.name
  description = "Keycloak認証のデータベース名"
}

output "keycloak_user_name" {
  value       = google_sql_user.keycloak_user.name
  description = "Keycloakデータベース接続のユーザー名"
}
