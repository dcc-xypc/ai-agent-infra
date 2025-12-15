variable "project_id" {
  description = "GCPプロジェクトIDです。"
  type        = string
  default     = "q14020-d-toyota-imap-dev"
}

variable "region" {
  description = "デプロイに使用する唯一のGCPリージョンです。（例：asia-northeast1）"
  type        = string
  default     = "asia-northeast1" 
}

variable "env_name" {
  description = "環境名（開発環境: dev または本番環境: prod）です。"
  type        = string
  default     = "dev"
}

variable "db_tier_config" {
  description = "環境に基づくインスタンスティアのマップです。"
  type        = map(string)
  default     = { "dev" = "db-g1-small", "prod" = "db-standard-2" }
}

# --- GitHub (標準) トリガー変数 ---
variable "github_repo_owner" {
  description = "リポジトリを所有するGitHubの組織名またはユーザー名です。"
  type        = string
  default     = "dcc-xypc"
}

variable "github_repo_name" {
  description = "GitHub上のリポジトリ名です。"
  type        = string
  default     = "cloudrun-demo-keycloak"
}

variable "trigger_branch" {
  description = "ビルドをトリガーするGitブランチです。"
  type        = string
  default     = "^main$"
}

# --- ネットワーク変数 ---
variable "external_cloudrun_sa_email" {
  description = "Cloud Run 运行服务账户的邮箱地址，用于执行应用代码。"
  type        = string
  default     = "sa-cloud-run-keycloak@q14020-d-toyota-imap-dev.iam.gserviceaccount.com" 
}
# --- ネットワーク変数 ---
variable "vpc_network_name" {
  description = "VPCネットワークのベース名です。"
  type        = string
  default     = "iac-custom-vpc"
}

variable "subnet_cidr" {
  description = "アプリケーションサブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.0.1.0/24" 
}

variable "connector_subnet_cidr" {
  description = "VPCアクセスコネクタ専用サブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.0.3.0/28"
}
variable "reserved_ip_range_name" {
  description = "Cloud SQLサービスネットワーク用に予約されたIP範囲の名前です。"
  type        = string
  default     = "google-managed-services-ip-range"
}

