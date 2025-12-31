variable "project_id" {
  description = "GCPプロジェクトIDです。"
  type        = string
  default     = "q14020-d-toyota-imap-dev"
}

variable "project_number" {
  description = "GCPプロジェクトNumberです。"
  type        = string
  default     = "807696689691"
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
  description = "PostgreSQLの管理者パスワードです。"
  type        = string
  default     = "pg_admin_password"
}

variable "mysql_admin_password" {
  description = "MySQLの管理者パスワードです。"
  type        = string
  default     = "mysql_admin_password"
}

variable "ai_agent_db_name" {
  description = "AIエージェントアプリケーションデータベース名です。"
  type        = string
  default     = "ai_agent"
}

variable "ai_agent_db_user" {
  description = "AIエージェントアプリケーションデータベースユーザーです。"
  type        = string
  default     = "ai_agent_user"
}

variable "ai_agent_db_password" {
  description = "AIエージェントアプリケーションデータベースパスワードです。"
  type        = string
  default     = "ai_agent_db_password"
}

variable "keycloak_db_name" {
  description = "Keycloak認証データベース名です。"
  type        = string
  default     = "keycloak"
}

variable "keycloak_db_user" {
  description = "Keycloak認証データベースユーザーです。"
  type        = string
  default     = "keycloak_user"
}

variable "keycloak_db_password" {
  description = "Keycloak認証データベースパスワードです。"
  type        = string
  default     = "keycloak_db_password"
}

# --- Cloud Run変数 --- 
variable "default_placeholder_image" {
  description = "CI/CDデプロイ前に使用するプレースホルダーイメージです。デフォルトはGoogle Cloud Run公式のhelloイメージです。"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "oauth2_proxy_image_gcr" {
  description = "OAuth2 Proxyサービスの目標イメージです。"
  type        = string
  #default     = "gcr.io/cloudrun/hello"
  default     = ""
}

variable "keycloak_admin_name" {
  description = "Keycloak管理者名です。"
  type        = string
  default     = "kcadmin"
}

variable "keycloak_admin_password" {
  description = "Keycloak管理者パスワードです。"
  type        = string
  default     = "keycloak_admin_password"
}

variable "oauth2_proxy_client_id" {
  description = "OAuth2 ProxyのクライアントIDです。"
  type        = string
  default     = "ai-agent-client"
}

variable "oauth2_proxy_client_secret" {
  description = "OAuth2 Proxyのクライアントシークレットです。"
  type        = string
  default     = "ZMflKrEpgeITQA5ocitK0AEcEeFrzTsl"
}

variable "oauth2_proxy_cookie_secret" {
  description = "OAuth2 Proxyのクッキーシークレットです。"
  type        = string
  default     = "5IW9m4YHDWHf8AkuCzU_3b1c1Q9NoLlCJW0lKxgvgXE="
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

variable "external_cloudrun_sa_email" {
  description = "Cloud Runサービスが使用するサービスアカウントのメールアドレスです。"
  type        = string
  default     = "sa-cloud-run-keycloak@q14020-d-toyota-imap-dev.iam.gserviceaccount.com" 
}

# --- ネットワーク変数 --- 
variable "vpc_network_name" {
  description = "VPCネットワークのベース名です。"
  type        = string
  default     = "iac-custom-vpc"
}

variable "subnet_cidr_con" {
  description = "VPCアクセスコネクタ専用サブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.1.0.0/28"
}

variable "subnet_cidr_sql" {
  description = "Cloud SQL専用サブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.2.0.0/24"
}

variable "subnet_cidr_psc" {
  description = "Private Service Connect専用サブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.3.0.0/24"
}

variable "subnet_cidr_ops" {
  description = "devopsサブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.4.0.0/24" 
}

variable "subnet_cidr_lb_int" {
  description = "devopsサブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.5.0.0/24" 
}

variable "subnet_cidr_lb_int_proxy" {
  description = "devopsサブネットのIP CIDR範囲です。"
  type        = string
  default     = "10.6.0.0/24"
}

variable "allowed_source_ip_ranges" {
  description = "外部ロードバランサへのアクセスを許可するIPアドレス範囲のリスト"
  type        = list(string)
  default     = ["13.228.59.248/32", "13.230.154.173/32", "52.192.4.186/32", "218.69.11.110/32"]
}

variable "enable_ops_nat" {
  description = "OpsサブネットのNATを有効にするかどうかです。"
  type        = bool
  default     = false
}

variable "tenant_domain" {
  description = "テナントフロントエンドアプリケーションとAPIのドメイン名です。"
  type        = string
  default     = "tenant1.ai-agent.tcic-cloud.com"
}

variable "auth_domain" {
  description = "Keycloak認証サービスのドメイン名です。"
  type        = string
  default     = "auth.ai-agent.tcic-cloud.com"
}
