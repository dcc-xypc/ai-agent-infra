# AI Agent インフラ構成およびデプロイガイド (README)

このリポジトリには、AI Agent システムのインフラ（Terraform）のソースコードが含まれています。

## 1. 事前準備 (Manual Setup)

デプロイを開始する前に、Google Cloud コンソールで以下のリソースを手動で作成・設定する必要があります。

### A. Secret Manager の設定
以下のシークレットを作成し、適切な値を保存してください。これらは Terraform および各サービスの実行時に参照されます。

| シークレット名 | 内容 |
| :--- | :--- |
| **`asahi-client-secret`** | **Keycloak クライアントの Client Secret** |
| `asahi_db_password` | Asahi 専用データベースユーザーのパスワード |
| `keycloak_admin_password` | Keycloak 管理画面の管理者パスワード |
| `keycloak_db_password` | Keycloak 用データベースユーザーのパスワード |
| `mysql_admin_password` | MySQL インスタンス全体の管理者 (root) パスワード |
| `pg_admin_password` | PostgreSQL 管理者パスワード |

---

## 2. 権限設定 (IAM Roles)

各サービスおよびデプロイフローを正常に動作させるため、以下のサービスアカウントに適切なロールを付与してください。

### ① Cloud Build 実行用サービスアカウント (デプロイ用)
**アカウント名**: `asahi-${var.env_name}-sa-cloud-build@${var.project_id}.iam.gserviceaccount.com`
**付与対象**: Cloud Build トリガー
**付与ロール**:
* `roles/serviceusage.serviceUsageAdmin`
* `roles/artifactregistry.writer`
* `roles/cloudsql.admin`
* `roles/compute.instanceAdmin.v1`
* `roles/compute.networkAdmin`
* `roles/compute.securityAdmin`
* `roles/compute.loadBalancerAdmin`
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

### ② Cloud Run 実行用サービスアカウント (ランタイム用)
**アカウント名**: `asahi-${var.env_name}-sa-cloud-run@${var.project_id}.iam.gserviceaccount.com`
**付与対象**: 全ての Cloud Run タスク
**付与ロール**:
* `roles/run.invoker`
* `roles/cloudsql.client`
* `roles/secretmanager.secretAccessor`

### ③ Devop用 GCE インスタンスサービスアカウント (運用操作用)
**アカウント名**: `asahi-${var.env_name}-sa-gce@${var.project_id}.iam.gserviceaccount.com`
**付与対象**: Devop 用 GCE インスタンス
**付与ロール**:
* `roles/secretmanager.secretAccessor`
* `roles/cloudsql.client`
* `roles/logging.logWriter`

---

## 3. Cloud Build トリガーの設定

### A. GitHub 連携 (リポジトリ接続)
Cloud Build が GitHub からソースコードを取得できるように、以下の手順で接続を作成します。

1.  Google Cloud コンソールの **[Cloud Build] > [リポジトリ]** ページに移動します。
2.  **[接続を作成]** をクリックします。
3.  **[GitHub (Cloud Build GitHub App)]** を選択し、[次へ] をクリックします。
4.  GitHub への認証画面が表示されるので、承認します。
5.  接続する GitHub アカウントまたは組織を選択し、**[Google Cloud Build をインストール]** をクリックして、対象のリポジトリを選択します。
6.  接続が完了すると、リポジトリ一覧に表示されます。

### B. トリガーの作成
1.  **[Cloud Build] > [トリガー]** ページに移動し、**[トリガーを作成]** をクリックします。
2.  **名前**: `asahi-breweries-infra-${var.env_name}`
3.  **イベント**: `ブランチにプッシュする`
4.  **リポジトリ**: 上記の手順で接続したリポジトリを選択します。
5.  **ブランチ**: `^${var.env_name}$`
6.  **形式**: `Cloud Build 構成ファイル (yaml)`
7.  **ファイルパス**: `cloudbuild.yaml`

---

## 4. 環境構築後の作業 (Post-Deployment Steps)

インフラのデプロイ完了後、システムの稼働を完了させるために以下の作業を順に実施してください。

1.  **認証サービスのビルド**: Cloud Build で `asahi-breweries-auth-service` の対象環境のトリガーを実行し、Docker イメージの更新とデプロイを行います。
2.  **Keycloak の設定**: `asahi-breweries-auth-service` リポジトリの README に従い、Keycloak 管理画面にログインして `asahi-realm`、`asahi-client`、および `asahi-user` を作成します。
3.  **Secret の更新**: 新しく作成した `asahi-client` の **Client Secret** の値を確認し、Secret Manager の `asahi-client-secret` の値を最新のシークレット値で更新します。
4.  **認証プロキシのビルド**: Cloud Build で `asahi-breweries-auth-proxy` の対象環境のトリガーを実行し、最新のシークレット値を反映させたイメージの更新とデプロイを行います。

---

## 5. トラブルシューティング

### 接続エラー (MySQL Access Denied)
Ops 仮想機（Devop 用 GCE）等から接続する際、`Access denied` エラーが出る場合は、MySQL 内部で対象ユーザー（例: `root`）のリモートアクセス権限が許可されているか確認してください。

### ネットワーク方式
本構成では **PSA (Private Services Access)** を利用しています。Cloud Build 用サービスアカウントに `roles/servicenetworking.networksAdmin` が付与されていることを確認してください。
