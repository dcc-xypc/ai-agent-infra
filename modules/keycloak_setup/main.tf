# 1. 在模块内部读取 Secret Manager


# 2. 配置内部 Provider
terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 4.4.0"
    }
  }
}

# 3. 定义 Keycloak 内部资源
resource "keycloak_realm" "realm" {
  realm   = "ai-agent-realm"
  enabled = true
}

resource "keycloak_openid_client" "client" {
  realm_id              = keycloak_realm.realm.id
  client_id             = var.oauth2_proxy_client_id
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris   = ["https://${var.tenant_domain}/oauth2/callback"]
}

resource "keycloak_user" "user" {
  realm_id = keycloak_realm.realm.id
  username = "ai-agent-user"
  enabled  = true
  initial_password {
    value     = "!QAZxsw2"
    temporary = false
  }
}
