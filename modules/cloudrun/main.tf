# -----------------------------------------------------------
# Cloud Run モジュール: Cloud Run サービス、専用サービスアカウント、IAM を作成
# -----------------------------------------------------------


# 1. Cloud Run サービス (単一リージョンサービス)
resource "google_cloud_run_v2_service" "app_service" {
  name     = "app-service-${var.env_name}" 
  location = var.region 
  project  = var.project_id

  template {
    service_account = var.external_cloudrun_sa_email
    
    containers {
      image = "gcr.io/cloudrun/hello" 
      env {
        name  = "CLOUD_SQL_CONN_NAME"
        value = var.db_connection_name
      }
    }
    
    
    vpc_access {
      connector = var.connector_id 
      egress    = "ALL_TRAFFIC" 
    }
  }

  # ALB 経由での呼び出しを可能にするためのトラフィック設定
  traffic {
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# 2. Cloud Run サービスアカウントの IAM 绑定 (Cloud SQL Client)
resource "google_project_iam_member" "cloudsql_client_binding" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# 3. Cloud Run サービスアカウントの IAM 绑定 (Serverless VPC Access User)
resource "google_project_iam_member" "vpc_access_user_binding" {
  project = var.project_id
  role    = "roles/vpcaccess.user"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# 4. Cloud Run の Public Invoker 権限を付与 (ALB からのアクセスを許可)
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.app_service.name
  role     = "roles/run.invoker"
  member   = "allUsers" 
}
