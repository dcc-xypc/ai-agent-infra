variable "project_id" {
  type        = string
  description = "GCPプロジェクトID"
}
variable "project_number" {
  type        = string
  description = "GCPプロジェクト番号"
}
variable "region" {
  type        = string
  description = "リージョン"
}
variable "env_name" {
  type        = string
  description = "環境名"
}
variable "connector_id" {
  type        = string
  description = "VPCアクセスコネクタID"
}
variable "internal_lb_ip_address" {
  type        = string
  description = "内部ロードバランサーのIPアドレス"
}
variable "external_cloudrun_sa_email" {
  type        = string
  description = "Cloud Run用の外部サービスアカウントメール"
}
variable "default_placeholder_image" {
  type        = string
  description = "デフォルトのプレースホルダーイメージ"
}
variable "oauth2_proxy_image_gcr" {
  type        = string
  description = "OAuth2 ProxyのGCRイメージURL"
}
variable "ai_agent_db_connection_name" {
  type        = string
  description = "AI Agentデータベースの接続名"
}
variable "ai_agent_db_name" {
  type        = string
  description = "AI Agentデータベース名"
}
variable "ai_agent_db_user" {
  type        = string
  description = "AI Agentデータベースユーザー"
}
variable "ai_agent_db_password" {
  type        = string
  description = "AI Agentデータベースパスワード"
  sensitive   = true
}
variable "keycloak_db_connection_name" {
  type        = string
  description = "Keycloakデータベースの接続名"
}
variable "keycloak_db_name" {
  type        = string
  description = "Keycloakデータベース名"
}
variable "keycloak_db_user" {
  type        = string
  description = "Keycloakデータベースユーザー"
}
variable "keycloak_db_password" {
  type        = string
  description = "Keycloakデータベースパスワード"
  sensitive   = true
}
variable "keycloak_admin_name" {
  type        = string
  description = "Keycloak管理者名"
}
variable "keycloak_admin_password" {
  type        = string
  description = "Keycloak管理者パスワード"
  sensitive   = true
}
variable "keycloak_external_url" {
  type        = string
  description = "Keycloakの外部URL"
}
variable "auth_domain" {
  type        = string
  description = "認証ドメイン"
}
variable "tenant_domain" {
  type        = string
  description = "テナントドメイン"
}
variable "oauth2_proxy_client_id" {
  type        = string
  description = "OAuth2 ProxyクライアントID"
}
variable "oauth2_proxy_client_secret" {
  type        = string
  description = "OAuth2 Proxyクライアントシークレット"
  sensitive   = true
}
variable "oauth2_proxy_cookie_secret" {
  type        = string
  description = "OAuth2 Proxyクッキーシークレット"
  sensitive   = true
}
variable "setup_keycloak_resources" {
  type = bool
}