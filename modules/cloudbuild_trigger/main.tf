# -----------------------------------------------------------
# Cloud Build トリガーモジュール: GitHubイベントをリッスン
# -----------------------------------------------------------

resource "google_cloudbuild_trigger" "app_ci_trigger" {
  project = var.project_id
  name    = "app-ci-trigger-${var.env_name}"
  
  # 標準 GitHub ホスト型リポジトリ設定
  github {
    owner = var.github_repo_owner
    name  = var.github_repo_name
    
    push {
      branch = var.trigger_branch
    }
  }

  filename = "cloudbuild.yaml" 
  
  # 代替変数 (CI/CDスクリプトで使用)
  substitutions = {
    _ENV_NAME  = var.env_name
    _REGION    = var.region 
  }
}
