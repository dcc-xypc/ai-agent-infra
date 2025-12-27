# modules/cloudsql/outputs.tf

# ----------------------------------------------------
# 1. Cloud SQL 实例连接名 (CLOUD_SQL_CONN_NAME)
# ----------------------------------------------------
output "instance_connection_name" {
  description = "The connection name for the Cloud SQL instance, used by Cloud Run."
  # 实例的 connection_name 属性会自动生成 'project:region:instance_name' 格式
  value       = google_sql_database_instance.postgres_instance.connection_name
}
output "mysql_instance_connection_name" {
  description = "The connection name for the Cloud SQL instance, used by Cloud Run."
  # 实例的 connection_name 属性会自动生成 'project:region:instance_name' 格式
  value       = google_sql_database_instance.mysql_instance.connection_name
}

# ----------------------------------------------------
# 2. AI Agent 数据库连接信息 (给 web-backend-app)
# ----------------------------------------------------
output "ai_agent_db_name" {
  description = "The database name for the AI Agent application."
  value       = google_sql_database.ai_agent_db.name
}

output "ai_agent_user_name" {
  description = "The username for the AI Agent database connection."
  value       = google_sql_user.ai_agent_user.name
}

# ----------------------------------------------------
# 3. Keycloak 数据库连接信息 (给 auth-keycloak-app)
# ----------------------------------------------------
output "keycloak_db_name" {
  description = "The database name for Keycloak authentication."
  value       = google_sql_database.keycloak_db.name
}

output "keycloak_user_name" {
  description = "The username for the Keycloak database connection."
  value       = google_sql_user.keycloak_user.name
}
