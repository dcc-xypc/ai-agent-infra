# -----------------------------------------------------------
# API 模块: 启用基础设施所需的所有 Google Cloud API
# -----------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID to enable services on."
  type        = string
}

# 1. 核心基础设施和网络 API
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  # 用于私有服务连接（Cloud SQL、Memorystore 等）
  project = var.project_id
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
  # 显式依赖 Compute API，确保网络基础已就绪
  depends_on = [google_project_service.compute] 
}

# 2. 数据库 API
resource "google_project_service" "sqladmin" {
  # 用于创建和管理 Cloud SQL 实例
  project = var.project_id
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# 3. Serverless 平台 API
resource "google_project_service" "cloudrun" {
  # 用于 Cloud Run 服务部署和管理 (解决了时序问题)
  project = var.project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.compute] # 依赖网络
}

resource "google_project_service" "vpcaccess" {
  # 用于 Serverless VPC Access Connector
  project = var.project_id
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project_service.compute] # 依赖网络
}

# 4. 镜像存储和构建 API
resource "google_project_service" "artifactregistry" {
  # 用于存储 Docker 镜像
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  # 用于运行 CI/CD 流水线
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# 5. IAM 和 Logging API
resource "google_project_service" "iam" {
  # 用于服务账户和 IAM 策略管理
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  # 用于日志记录
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
