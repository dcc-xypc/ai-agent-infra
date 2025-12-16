# -----------------------------------------------------------
# Cloud SQL モジュール: Cloud SQL インスタンスとデータベースを作成
# -----------------------------------------------------------

# 1. Cloud SQL インスタンス (プライベート IP のみ)
resource "google_sql_database_instance" "postgres_instance" {
  database_version = "POSTGRES_17"
  name             = "ai-agent-pg-instance-${var.env_name}"
  project          = var.project_id
  region           = var.region

  settings {
    tier = var.db_tier_config[var.env_name] 
    disk_size = 10 
    disk_type = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false 
      private_network = var.private_network_link 
    }
    maintenance_window {
      day  = 7 # Sunday
      hour = 5
    }
  }
  deletion_protection = false
}

resource "google_sql_user" "postgres_admin" {
  name     = "postgres" 
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
  password = var.pg_admin_password

  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}

# ----------------------------------------------------
# 2. 创建应用程序数据库 (AI Agent)
# ----------------------------------------------------
resource "google_sql_database" "ai_agent_db" {
  name     = var.ai_agent_db_name
  project  = var.project_id
  instance = google_sql_database_instance.postgres_instance.name
  
  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}

# ----------------------------------------------------
# 3. 创建身份验证数据库 (Keycloak)
# ----------------------------------------------------
resource "google_sql_database" "keycloak_db" {
  name     = var.keycloak_db_name
  project  = var.project_id
  instance = google_sql_database_instance.postgres_instance.name
  
  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}
# ----------------------------------------------------
# 4. 创建 AI Agent 数据库用户
# ----------------------------------------------------
resource "google_sql_user" "ai_agent_user" {
  name     = "ai_agent_user"
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
  
  password = var.ai_agent_db_password

  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}

# ----------------------------------------------------
# 5. 创建 Keycloak 数据库用户
# ----------------------------------------------------
resource "google_sql_user" "keycloak_user" {
  name     = "keycloak_user"
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
  
  password = var.keycloak_db_password

  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}
