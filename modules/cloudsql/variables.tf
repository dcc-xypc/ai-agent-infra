variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "env_name" {
  type = string
}
variable "db_tier_config" {
  type = map(string)
}
variable "pg_admin_password" {
  type = string
}
variable "ai_agent_db_name" {
  type = string
}
variable "ai_agent_db_user" {
  type = string
}
variable "ai_agent_db_password" {
  type = string
}
variable "keycloak_db_name" {
  type = string
}
variable "keycloak_db_user" {
  type = string
}
variable "keycloak_db_password" {
  type = string
}
variable "private_network_link" {
  type = string
}
