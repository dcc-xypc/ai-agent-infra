# -----------------------------------------------------------
# Cloud SQL モジュール: Cloud SQL インスタンスとデータベースを作成
# -----------------------------------------------------------

# 0. パスワードを取得
data "google_secret_manager_secret_version" "pg_admin_password" {
  secret  = var.pg_admin_password
  project = var.project_id
}

data "google_secret_manager_secret_version" "mysql_admin_password" {
  secret  = var.mysql_admin_password
  project = var.project_id
}

# AI Agent データベースパスワードを取得
data "google_secret_manager_secret_version" "ai_agent_db_password" {
  secret  = var.ai_agent_db_password
  project = var.project_id
}

# Keycloak データベースパスワードを取得
data "google_secret_manager_secret_version" "keycloak_db_password" {
  secret  = var.keycloak_db_password
  project = var.project_id
}

# 1. Cloud SQL インスタンス (PostgreSQL / プライベート IP のみ)
resource "google_sql_database_instance" "postgres_instance" {
  name             = "${var.resource_prefix}-sql-pg"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_17"

  settings {
    edition = "ENTERPRISE"
    tier      = var.db_tier_config[var.env_name]
    disk_type = "PD_SSD"
    disk_size = 10

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network_link
    }
    maintenance_window {
      day  = 7 # Sunday
      hour = 5
    }

    user_labels = var.common_labels
  }
  deletion_protection = false
}

resource "google_sql_user" "postgres_admin" {
  name     = "postgres" 
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
  password = data.google_secret_manager_secret_version.pg_admin_password.secret_data

  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}

# 1.1 新增 MySQL 实例 (私有 IP 模式)
resource "google_sql_database_instance" "mysql_instance" {
  name             = "${var.resource_prefix}-sql-mysql"
  project          = var.project_id
  region           = var.region
  database_version = "MYSQL_8_0"

  settings {
    tier      = var.db_tier_config[var.env_name]
    disk_type = "PD_SSD"
    disk_size = 10

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network_link
    }
    
    database_flags {
      name  = "character_set_server"
      value = "utf8mb4"
    }

    user_labels = var.common_labels
  }
  deletion_protection = false
}

resource "google_sql_user" "mysql_admin" {
  name     = "root"
  instance = google_sql_database_instance.mysql_instance.name
  project  = var.project_id
  password = data.google_secret_manager_secret_version.mysql_admin_password.secret_data

  depends_on = [google_sql_database_instance.mysql_instance]
}

# ----------------------------------------------------
# 2. アプリケーションデータベースを作成 (AI Agent)
# ----------------------------------------------------
resource "google_sql_database" "ai_agent_db" {
  name       = var.ai_agent_db_name
  project    = var.project_id
  instance   = google_sql_database_instance.mysql_instance.name
  depends_on = [
    google_sql_database_instance.mysql_instance
  ]
}

# ----------------------------------------------------
# 3. 認証データベースを作成 (Keycloak)
# ----------------------------------------------------
resource "google_sql_database" "keycloak_db" {
  name       = var.keycloak_db_name
  project    = var.project_id
  instance   = google_sql_database_instance.postgres_instance.name
  
  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}

# ----------------------------------------------------
# 4. AI Agent データベースユーザーを作成
# ----------------------------------------------------
resource "google_sql_user" "ai_agent_user" {
  name     = var.ai_agent_db_user
  instance = google_sql_database_instance.mysql_instance.name
  project  = var.project_id
  
  host     = "%"
  password = data.google_secret_manager_secret_version.ai_agent_db_password.secret_data

  depends_on = [
    google_sql_database_instance.mysql_instance
  ]
}

# ----------------------------------------------------
# 5. Keycloak データベースユーザーを作成
# ----------------------------------------------------
resource "google_sql_user" "keycloak_user" {
  name     = var.keycloak_db_user
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
  
  password = data.google_secret_manager_secret_version.keycloak_db_password.secret_data

  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}
