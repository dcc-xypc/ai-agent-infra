# -----------------------------------------------------------
# API モジュール: インフラストラクチャに必要なすべての Google Cloud API を有効化
# -----------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID to enable services on."
  type        = string
}

# 1. コアインフラストラクチャとネットワーク API
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  # プライベートサービス接続に使用（Cloud SQL、Memorystore など）
  project = var.project_id
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
  # Compute API に明示的に依存し、ネットワーク基盤が準備済みであることを確認
  depends_on = [google_project_service.compute]
}

# 2. データベース API
resource "google_project_service" "sqladmin" {
  # Cloud SQL インスタンスの作成と管理に使用
  project = var.project_id
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# 3. Serverless プラットフォーム API
resource "google_project_service" "cloudrun" {
  # Cloud Run サービスのデプロイと管理に使用 (タイミング問題を解決)
  project = var.project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.compute] # ネットワークに依存
}

resource "google_project_service" "vpcaccess" {
  # 用于 Serverless VPC Access Connector
  project = var.project_id
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.compute] # 依赖网络
}

# 4. イメージストレージとビルド API
resource "google_project_service" "artifactregistry" {
  # Docker イメージのストレージに使用
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  # CI/CD パイプラインの実行に使用
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# 5. IAM および Logging API
resource "google_project_service" "iam" {
  # サービスアカウントおよび IAM ポリシーの管理に使用
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  # ログ記録に使用
  project = var.project_id
  service = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iap" {
  # 用于日志记录
  project = var.project_id
  service = "iap.googleapis.com"
  disable_on_destroy = false
}
