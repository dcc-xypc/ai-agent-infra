# -----------------------------------------------------------
# Cloud SQL モジュール: Cloud SQL インスタンスとデータベースを作成
# -----------------------------------------------------------

# 1. Cloud SQL インスタンス (プライベート IP のみ)
resource "google_sql_database_instance" "postgres_instance" {
  database_version = "POSTGRES_15"
  name             = "pg-instance-${var.env_name}"
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
  }
  deletion_protection = false
}

# 2. デフォルトデータベース
resource "google_sql_database" "default_db" {
  name     = "app_database"
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
}
