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

### B. 運用操作用サービスアカウントの作成と設定 (Manual Setup)

組織のセキュリティポリシー（外部ドメインによる直接 SSH の制限など）に対応するため、外部ユーザーは「サービスアカウントの借用 (Impersonation)」を利用して VM に接続します。以下の手順で専用のサービスアカウントを作成し、適切な権限を付与してください。

#### 1. 運用専用サービスアカウント (Ops SA) の作成
* **アカウント名**: `asahi-${var.env_name}-sa-vm-devops-vm`
* **用途**: IAP トンネルの確立、および OS Login を利用した VM へのログイン実行用。

#### 2. サービスアカウント自体への権限付与 (IAM Roles)
作成した **サービスアカウント（SA）に対して**、プロジェクトレベルで以下のロールを付与します。これらが不足していると、接続時に `Permission denied (publickey)` エラーが発生します。

| ロール名 | ロール ID | 用途 |
| :--- | :--- | :--- |
| **IAP ユーザー** | `roles/iap.tunnelResourceAccessor` | IAP トンネル経由のトラフィック転送を許可 |
| **Compute OS Admin ログイン** | `roles/compute.osAdminLogin` | OS Login による sudo 権限付きログインを許可 |
| **サービス アカウント ユーザー** | `roles/iam.serviceAccountUser` | **重要**: SA が VM のアイデンティティとして動作することを許可 |

#### 3. 外部ユーザーへの借用権限の付与
外部パートナー（例：`external.user@xxxx.com`）がこの SA を利用できるよう、**サービスアカウントのリソース単位**で以下のロールを付与してください。

* **対象リソース**: 上記で作成した `asahi-${var.env_name}-sa-vm-devops-vm`
* **付与ロール**: `roles/iam.serviceAccountTokenCreator` (サービス アカウント トークン作成者)
* **用途**: 外部ユーザーがこの SA の一時的な認証トークンを生成し、SA の ID を借用することを許可します。

### 4. 運用者向け SSH 接続手順

セットアップ完了後、運用担当者はローカル端末または Cloud Shell から以下のコマンドを使用して接続します。

```bash
gcloud compute ssh [VM_NAME] \
    --project=${var.project_id} \
    --zone=${var.zone} \
    --tunnel-through-iap \
    --impersonate-service-account="asahi-${var.env_name}-sa-vm-devops-vm@${var.project_id}.iam.gserviceaccount.com"
```
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

## 5. 運用操作手順 (Cloud Shell & DB 接続)

### ※ 実行ユーザー（個人アカウント）に必要な権限
Cloud Shell から SSH ログインを実行するユーザーには、以下のロールが必要です：
* `roles/compute.osLoginExternalUser` (外部組織アカウントの場合)
* `roles/compute.osAdminLogin` (sudoを使えてログインの場合)
* `roles/iap.tunnelResourceAccessor` (IAP 経由の接続に必須)

### A. Cloud Shell の起動
1.  Google Cloud コンソール画面右上の **[Cloud Shell をアクティブにする]** アイコン（`>_`）をクリックします。

### B. 運用用 GCE インスタンスへの SSH ログイン
以下のコマンドを実行し、IAP トンネル経由で運用用 GCE インスタンス（Devop機）に接続します。
```bash
gcloud compute ssh asahi-${var.env_name}-sa-gce \
    --project=${var.project_id} \
    --zone=asia-northeast1-c \
    --tunnel-through-iap
```

### C. データベースへの接続 (GCE ログイン後に実行)
GCE インスタンス内から、プライベート IP を使用して各データベースに接続します。

* **PostgreSQL (Keycloak用) への接続**:
    ```bash
    psql -h <DB_PRIVATE_IP_ADDRESS> -U postgres
    ```
* **MySQL (アプリ用) への接続**:
    ```bash
    mysql -h <DB_PRIVATE_IP_ADDRESS> -u root -p
    ```
    *※ `<DB_PRIVATE_IP_ADDRESS>` は Google Cloud コンソールの Cloud SQL インスタンス詳細画面で確認してください。*
---

## 6. トラブルシューティング

### 接続エラー (MySQL Access Denied)
Ops 仮想機（Devop 用 GCE）等から接続する際、`Access denied` エラーが出る場合は、MySQL 内部で対象ユーザー（例: `root`）のリモートアクセス権限が許可されているか確認してください。

### ネットワーク方式
本構成では **PSA (Private Services Access)** を利用しています。Cloud Build 用サービスアカウントに `roles/servicenetworking.networksAdmin` が付与されていることを確認してください。
