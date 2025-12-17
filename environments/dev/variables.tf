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

variable "pg_admin_password" {
  description = "The password for the AI Agent database instance."
  type        = string
  default     = "!QAZxsw2"
}

variable "ai_agent_db_name" {
  description = "The name for the AI Agent application database."
  type        = string
  default     = "ai_agent"
}

variable "ai_agent_db_user" {
  description = "The user for the AI Agent application database."
  type        = string
  default     = "ai_agent_user"
}

variable "ai_agent_db_password" {
  description = "The password for the AI Agent application database."
  type        = string
  default     = "!QAZxsw2"
}

variable "keycloak_db_name" {
  description = "The name for the Keycloak authentication database."
  type        = string
  default     = "keycloak"
}

variable "keycloak_db_user" {
  description = "The user for the Keycloak authentication database."
  type        = string
  default     = "keycloak_user"
}

variable "keycloak_db_password" {
  description = "The password for the Keycloak authentication database."
  type        = string
  default     = "!QAZxsw2"
}

# --- Cloud Run変数 ---
variable "default_placeholder_image" {
  description = "CI/CD 部署之前使用的占位符镜像。默认使用 Google Cloud Run 官方 hello 镜像。"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "oauth2_proxy_image" {
  description = "OAuth2 Proxy 服务的容器镜像，必须指向一个实际的 Proxy 镜像。"
  type        = string
  default     = "quay.io/oauth2-proxy/oauth2-proxy:v7.13.0-amd64"
}

variable "keycloak_admin_name" {
  description = "The name for the Keycloak authentication database."
  type        = string
  default     = "kcadmin"
}

variable "keycloak_admin_password" {
  description = "The password for the Keycloak authentication database."
  type        = string
  default     = "!QAZxsw2"
}

variable "keycloak_external_url" {
  description = "The password for the Keycloak authentication database."
  type        = string
  default     = "keycloak.internal.need.change"
}

variable "oauth2_proxy_client_id" {
  description = "The password for the Keycloak authentication database."
  type        = string
  default     = "dummy"
}

variable "oauth2_proxy_client_secret" {
  description = "The password for the Keycloak authentication database."
  type        = string
  default     = "dummy"
}

variable "oauth2_proxy_cookie_secret" {
  description = "The password for the Keycloak authentication database."
  type        = string
  default     = "dummy"
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

