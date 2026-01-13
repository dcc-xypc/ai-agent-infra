# AI Agent インフラ構成およびデプロイガイド (README)

このリポジトリには、AI Agent システムのインフラ（Terraform）とバックエンド（ASP.NET Core）のソースコードが含まれています。

## 1. 事前準備 (Manual Setup)

デプロイを開始する前に、Google Cloud コンソールで以下のリソースを手動で作成・設定する必要があります。

### A. Secret Manager の設定
以下のシークレットを作成し、適切な値を保存してください。これらは Terraform および各サービスの実行時に参照されます。

| シークレット名 | 内容 |
| :--- | :--- |
| `ai_agent_db_password` | AI Agent 専用データベースユーザーのパスワード |
| `keycloak_admin_password` | Keycloak 管理画面の管理者パスワード |
| `keycloak_db_password` | Keycloak 用データベースユーザーのパスワード |
| `mysql_admin_password` | MySQL インスタンス全体の管理者 (root) パスワード |
| `pg_admin_password` | PostgreSQL 管理者パスワード |

### B. ドメインと DNS
* Terraform 実行後、作成された外部静的 IP アドレスを確認し、ドメインの **A レコード** をその IP に設定してください。
* SSL 証明書のプロビジョニングには、DNS の伝播後に時間がかかる場合があります。

---

## 2. 権限設定 (IAM Roles)

デプロイと実行のために、以下の 2 つのサービスアカウントに適切な権限を付与する必要があります。

### ① Cloud Build 実行用サービスアカウント
**アカウント名**: `asahi-${var.env_name}-sa-cloud-build@{var.project_id}.iam.gserviceaccount.com`

このアカウントは Terraform の実行およびアーティファクトのビルドに使用されます。以下のロールを付与してください：
* `roles/artifactregistry.writer`
* `roles/cloudbuild.builds.editor`
* `roles/cloudsql.admin`
* `roles/compute.admin`
* `roles/compute.instanceAdmin.v1`
* `roles/iam.serviceAccountAdmin`
* `roles/iam.serviceAccountUser`
* `roles/iam.serviceAccountViewer`
* `roles/iap.tunnelResourceAccessor`
* `roles/logging.logWriter`
* `roles/run.admin`
* `roles/secretmanager.secretAccessor`
* `roles/secretmanager.viewer`
* `roles/servicenetworking.networksAdmin`
* `roles/storage.objectAdmin`
* `roles/vpcaccess.admin`

### ② Cloud Run 実行用サービスアカウント
**アカウント名**: `asahi-${var.env_name}-sa-cloud-run@{var.project_id}.iam.gserviceaccount.com`

このアカウントは Cloud Run サービスが実行時にリソースへアクセスするために使用されます：
* `roles/run.invoker`
* `roles/cloudsql.client` (Unix Socket 経由の接続に必須)
* `roles/secretmanager.secretAccessor` (データベースパスワード等の取得)

---

## 3. Cloud Build トリガーの設定

1. **GitHub/GitLab 連携**: Google Cloud コンソールの Cloud Build ページでリポジトリを接続します。
2. **トリガー作成**:
   - **イベント**: ブランチへのプッシュ
   - **ブランチ**: `^main$`
   - **形式**: `Cloud Build 構成ファイル (yaml)`
   - **ファイルパス**: `cloudbuild.yaml`
3. **代入変数 (Substitutions)**:
   - `_REGION`: `asia-northeast1`
   - `_RESOURCE_PREFIX`: `asahi-dev`

---

## 4. バックエンドの実装に関する注意 (C# / .NET 8)

### データベース接続 (MySqlConnector)
Cloud Run から Cloud SQL へ Unix Socket 経由で接続する場合、`MySqlConnector` を使用し、以下の形式で `ConnectionString` を構築してください：

```csharp
var builder = new MySqlConnectionStringBuilder
{
    Server = $"/cloudsql/{dbConnName}", // project:region:instance
    UserID = dbUser,
    Password = dbPass,
    Database = dbName,
    SslMode = MySqlSslMode.None,
    ConnectionProtocol = MySqlConnectionProtocol.UnixSocket // 必須設定
};
