# -----------------------------------------------------------
# Cloud SQL モジュール: Cloud SQL インスタンスとデータベースを作成
# -----------------------------------------------------------

#  0. 获取密码
data "google_secret_manager_secret_version" "pg_admin_password" {
  secret  = var.pg_admin_password
  project = var.project_id
}

data "google_secret_manager_secret_version" "mysql_admin_password" {
  secret  = var.mysql_admin_password
  project = var.project_id
}

# 获取 AI Agent 数据库密码
data "google_secret_manager_secret_version" "ai_agent_db_password" {
  secret  = var.ai_agent_db_password
  project = var.project_id
}

# 获取 Keycloak 数据库密码
data "google_secret_manager_secret_version" "keycloak_db_password" {
  secret  = var.keycloak_db_password
  project = var.project_id
}

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
  password = data.google_secret_manager_secret_version.pg_admin_password.secret_data

  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}
# 1.1 新增 MySQL 实例 (私有 IP 模式)
resource "google_sql_database_instance" "mysql_instance" {
  database_version = "MYSQL_8_0"  # 指定为 MySQL
  name             = "ai-agent-mysql-instance-${var.env_name}"
  project          = var.project_id
  region           = var.region

  settings {
    tier      = var.db_tier_config[var.env_name] 
    disk_size = 10 
    disk_type = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false 
      private_network = var.private_network_link 
    }
    
    # MySQL 特有的配置项（可选，如不区分大小写等）
    database_flags {
      name  = "character_set_server"
      value = "utf8mb4"
    }
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
# 2. 创建应用程序数据库 (AI Agent)
# ----------------------------------------------------
resource "google_sql_database" "ai_agent_db" {
  name     = var.ai_agent_db_name
  project  = var.project_id
  instance = google_sql_database_instance.mysql_instance.name
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
  name     = var.ai_agent_db_user
  instance = google_sql_database_instance.mysql_instance.name
  project  = var.project_id
  
  password = data.google_secret_manager_secret_version.ai_agent_db_password.secret_data

  depends_on = [
    google_sql_database_instance.postgres_instance
  ]
}

# ----------------------------------------------------
# 5. 创建 Keycloak 数据库用户
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
