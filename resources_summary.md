# GCP AI Agent Infra 资源清单

## 1. API 模块 (modules/api/main.tf)
| 资源名称 | 资源类型 | 描述 | 实际创建的名称 |
|---------|---------|------|--------------|
| compute | google_project_service | Compute Engine API | compute.googleapis.com |
| servicenetworking | google_project_service | Service Networking API | servicenetworking.googleapis.com |
| sqladmin | google_project_service | Cloud SQL Admin API | sqladmin.googleapis.com |
| cloudrun | google_project_service | Cloud Run API | run.googleapis.com |

## 2. VPC 模块 (modules/vpc/main.tf)
| 资源名称 | 资源类型 | 描述 | 实际创建的名称 |
|---------|---------|------|--------------|
| vpc_network | google_compute_network | VPC 网络 | iac-custom-vpc-dev |
| default_internet_route | google_compute_route | 默认互联网路由 | default-internet-gateway-route |
| app_subnet | google_compute_subnetwork | 应用子网 | iac-custom-vpc-subnet-dev |
| ops_subnet | google_compute_subnetwork | DevOps VM 专用子网 | sb-ops-dev |
| connector_subnet | google_compute_subnetwork | VPC 访问连接器专用子网 | iac-custom-vpc-connector-dev |
| main_connector | google_vpc_access_connector | VPC 访问连接器 | cloudrun-connector-dev |
| private_ip_range | google_compute_global_address | Cloud SQL 对等连接用 IP 范围 | google-managed-services-ip-range |
| vpc_peering_connection | google_service_networking_connection | 服务网络连接（VPC 对等） | - |
| proxy_only_subnet | google_compute_subnetwork | Internal ALB 用 Proxy-Only 子网 | proxy-only-subnet-dev |
| internal_lb_static_ip | google_compute_address | Internal ALB 用静态内部 IP | internal-lb-ip-dev |
| router (条件) | google_compute_router | Cloud NAT 路由器（仅当 enable_ops_nat 为 true 时创建） | router-dev |
| nat (条件) | google_compute_router_nat | Cloud NAT 配置（仅当 enable_ops_nat 为 true 时创建） | nat-dev |

## 3. Cloud SQL 模块 (modules/cloudsql/main.tf)
| 资源名称 | 资源类型 | 描述 | 实际创建的名称 |
|---------|---------|------|--------------|
| postgres_instance | google_sql_database_instance | PostgreSQL 数据库实例 | ai-agent-pg-instance-dev |
| postgres_admin | google_sql_user | PostgreSQL 管理员用户 | postgres |
| mysql_instance | google_sql_database_instance | MySQL 数据库实例 | ai-agent-mysql-instance-dev |
| mysql_admin | google_sql_user | MySQL 管理员用户 | root |
| ai_agent_db | google_sql_database | AI Agent 应用数据库 | ai_agent |
| keycloak_db | google_sql_database | Keycloak 认证数据库 | keycloak |
| ai_agent_user | google_sql_user | AI Agent 数据库用户 | ai_agent_user |
| keycloak_user | google_sql_user | Keycloak 数据库用户 | keycloak_user |

## 4. Ops 模块 (modules/ops/main.tf)
| 资源名称 | 资源类型 | 描述 | 实际创建的名称 |
|---------|---------|------|--------------|
| ops_vm | google_compute_instance | 运维管理专用 VM | ops-vm-dev |
| allow_iap_ssh_ops | google_compute_firewall | IAP 专用 SSH 访问防火墙规则 | fw-allow-iap-ssh-ops-dev |

## 5. Cloud Run 模块 (modules/cloudrun/main.tf)
| 资源名称 | 资源类型 | 描述 | 实际创建的名称 |
|---------|---------|------|--------------|
| web_frontend_app | google_cloud_run_v2_service | 前端 Web 应用 | web-frontend-app-dev |
| web_frontend_invoker | google_cloud_run_v2_service_iam_member | 前端应用访问权限 | - |
| web_backend_app | google_cloud_run_v2_service | Web 后端应用 | web-backend-app-dev |
| web_backend_invoker | google_cloud_run_v2_service_iam_member | 后端应用访问权限 | - |
| auth_keycloak_app | google_cloud_run_v2_service | Keycloak 认证服务 | auth-keycloak-app-dev |
| auth_keycloak_invoker | google_cloud_run_v2_service_iam_member | Keycloak 服务访问权限 | - |
| oauth2_proxy_app | google_cloud_run_v2_service | OAuth2 Proxy 服务 | oauth2-proxy-app-dev |
| oauth2_proxy_invoker | google_cloud_run_v2_service_iam_member | OAuth2 Proxy 服务访问权限 | - |

## 6. Load Balancer 模块 (modules/loadbalancer/main.tf)
| 资源名称 | 资源类型 | 描述 | 实际创建的名称 |
|---------|---------|------|--------------|
| lb_ip | google_compute_global_address | 全局静态外部 IP | lb-ip-dev |
| frontend_neg | google_compute_region_network_endpoint_group | 前端应用 Serverless NEG | frontend-neg-dev |
| proxy_neg | google_compute_region_network_endpoint_group | OAuth2 Proxy Serverless NEG | proxy-neg-dev |
| keycloak_neg | google_compute_region_network_endpoint_group | Keycloak 服务 Serverless NEG | keycloak-neg-dev |
| backend_neg | google_compute_region_network_endpoint_group | 后端应用 Serverless NEG | backend-neg-dev |
| frontend_backend | google_compute_backend_service | 前端后端服务 | frontend-backend-dev |
| proxy_backend | google_compute_backend_service | Proxy 后端服务 | proxy-backend-dev |
| keycloak_backend | google_compute_backend_service | Keycloak 后端服务 | keycloak-backend-dev |
| default | google_compute_managed_ssl_certificate | Google 管理的 SSL 证书 | managed-cert-dev |
| url_map | google_compute_url_map | URL 路由映射 | url-map-dev |
| https_redirect | google_compute_url_map | HTTP 到 HTTPS 重定向配置 | https-redirect-dev |
| https_proxy | google_compute_target_https_proxy | HTTPS 代理 | https-proxy-dev |
| http_redirect_proxy | google_compute_target_http_proxy | HTTP 重定向代理 | http-proxy-dev |
| https_rule | google_compute_global_forwarding_rule | HTTPS 转发规则 | forwarding-rule-https-dev |
| http_rule | google_compute_global_forwarding_rule | HTTP 转发规则 | forwarding-rule-http-dev |
| internal_backend | google_compute_region_backend_service | 内部后端服务 | internal-backend-dev |
| internal_url_map | google_compute_region_url_map | 内部 URL 路由映射 | internal-url-map-dev |
| internal_target_proxy | google_compute_region_target_http_proxy | 内部 HTTP 代理 | internal-target-proxy-dev |
| internal_forwarding_rule | google_compute_forwarding_rule | 内部转发规则 | internal-forwarding-rule-dev |

## 7. Cloud Build Trigger 模块 (modules/cloudbuild_trigger/main.tf)
| 资源名称 | 资源类型 | 描述 | 实际创建的名称 |
|---------|---------|------|--------------|
| app_ci_trigger | google_cloudbuild_trigger | GitHub 事件触发的 CI/CD 构建触发器 | app-ci-trigger-dev |

## 注意事项
- 条件资源仅在特定条件满足时创建
- 数据资源（data）未包含在此清单中
- 本地资源（local）未包含在此清单中
- 此清单基于当前代码库中的 Terraform 资源定义
- 实际创建的名称基于变量默认值计算得出，实际部署时可能会根据环境配置有所不同