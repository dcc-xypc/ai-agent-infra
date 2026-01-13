# =================================================================
# 1. 基本的な環境とプロジェクト変数
# =================================================================

variable "project_id" {
  description = "GCPプロジェクトIDです。"
  type        = string
}

variable "project_number" {
  description = "GCPプロジェクトNumberです。"
  type        = string
}

variable "region" {
  description = "デプロイに使用する唯一のGCPリージョンです。（例：asia-northeast1）"
  type        = string
}

variable "env_name" {
  description = "環境名（開発環境: dev または本番環境: prod）です。"
  type        = string
}

# =================================================================
# 2. データベースと認証設定
# =================================================================

variable "db_tier_config" {
  description = "Cloud SQL インスタンスのティア（マシンタイプ）です。"
  type        = string
}

variable "pg_admin_password" {
  description = "PostgreSQLの管理者パスワードです。"
  type        = string
  sensitive   = true
}

variable "mysql_admin_password" {
  description = "MySQLの管理者パスワードです。"
  type        = string
  sensitive   = true
}

variable "ai_agent_db_name" {
  description = "AIエージェントアプリケーションデータベース名です。"
  type        = string
}

variable "ai_agent_db_user" {
  description = "AIエージェントアプリケーションデータベースユーザーです。"
  type        = string
}

variable "ai_agent_db_password" {
  description = "AIエージェントアプリケーションデータベースパスワードです。"
  type        = string
  sensitive   = true
}

variable "keycloak_db_name" {
  description = "Keycloak認証データベース名です。"
  type        = string
}

variable "keycloak_db_user" {
  description = "Keycloak認証データベースユーザーです。"
  type        = string
}

variable "keycloak_db_password" {
  description = "Keycloak認証データベースパスワードです。"
  type        = string
  sensitive   = true
}

# =================================================================
# 3. Cloud Run 関連変数
# =================================================================

variable "default_placeholder_image" {
  description = "CI/CDデプロイ前に使用するプレースホルダーイメージです。"
  type        = string
}

variable "oauth2_proxy_image_gcr" {
  description = "OAuth2 Proxyサービスの目標イメージです。"
  type        = string
}

variable "keycloak_admin_name" {
  description = "Keycloak管理者名です。"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Keycloak管理者パスワードです。"
  type        = string
  sensitive   = true
}

variable "oauth2_proxy_client_id" {
  description = "OAuth2 ProxyのクライアントIDです。"
  type        = string
}

variable "oauth2_proxy_realm_name" {
  description = "OAuth2 Proxyのレルム名称です。"
  type        = string
}

variable "oauth2_proxy_client_secret" {
  description = "OAuth2 Proxyのクライアントシークレットです。"
  type        = string
  sensitive   = true
}

variable "oauth2_proxy_cookie_secret" {
  description = "OAuth2 Proxyのクッキーシークレットです。"
  type        = string
  sensitive   = true
}

variable "external_cloudrun_sa_email" {
  description = "Cloud Runサービスが使用するサービスアカウントのメールアドレスです。"
  type        = string
}

# =================================================================
# 4. GitHub トリガー / CI/CD
# =================================================================

variable "github_repo_owner" {
  description = "リポジトリを所有するGitHubの組織名またはユーザー名です。"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub上のリポジトリ名です。"
  type        = string
}

variable "trigger_branch" {
  description = "ビルドをトリガーするGitブランチです。"
  type        = string
}

# =================================================================
# 5. ネットワーク変数
# =================================================================

variable "vpc_network_name" {
  description = "VPCネットワークのベース名です。"
  type        = string
}

variable "subnet_cidr_con" {
  description = "VPCアクセスコネクタ専用サブネットのIP CIDR範囲です。"
  type        = string
}

variable "subnet_cidr_sql" {
  description = "Cloud SQL専用サブネットのIP CIDR範囲です。"
  type        = string
}

variable "subnet_cidr_psc" {
  description = "Private Service Connect専用サブネットのIP CIDR範囲です。"
  type        = string
}

variable "subnet_cidr_ops" {
  description = "devopsサブネットのIP CIDR範囲です。"
  type        = string
}

variable "subnet_cidr_lb_int" {
  description = "内部LB用サブネットのIP CIDR範囲です。"
  type        = string
}

variable "subnet_cidr_lb_int_proxy" {
  description = "内部LBプロキシ用サブネットのIP CIDR範囲です。"
  type        = string
}

variable "allowed_source_ip_ranges" {
  description = "外部ロードバランサへのアクセスを許可するIPアドレス範囲のリスト"
  type        = list(string)
}

variable "enable_ops_nat" {
  description = "OpsサブネットのNATを有効にするかどうかです。"
  type        = bool
}

variable "tenant_domain" {
  description = "テナントフロントエンドアプリケーションとAPIのドメイン名です。"
  type        = string
}

variable "auth_domain" {
  description = "Keycloak認証サービスのドメイン名です。"
  type        = string
}

# =================================================================
# 6. リソーススペック
# =================================================================

variable "cloud_run_specs" {
  description = "CloudRunコンテナのリソースLimits"
  type = map(object({
    cpu    = string
    memory = string
  }))
}
