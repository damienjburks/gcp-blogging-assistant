# OpenAI Auth Token
resource "google_secret_manager_secret" "openai_authtoken" {
  secret_id = "openai-auth-token"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "openai_authtoken_version" {
  secret      = google_secret_manager_secret.openai_authtoken.id
  secret_data = var.OPENAI_AUTH_TOKEN
}

# Git Username
resource "google_secret_manager_secret" "git_username" {
  secret_id = "git-username"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "git_username_version" {
  secret      = google_secret_manager_secret.git_username.id
  secret_data = var.GIT_USERNAME
}

# Git Auth Token
resource "google_secret_manager_secret" "git_authtoken" {
  secret_id = "git-auth-token"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "git_authtoken_version" {
  secret      = google_secret_manager_secret.git_authtoken.id
  secret_data = var.GIT_AUTH_TOKEN
}

# YouTube Auth Token
resource "google_secret_manager_secret" "youtube_authtoken" {
  secret_id = "youtube-auth-token"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "youtube_authtoken_version" {
  secret      = google_secret_manager_secret.youtube_authtoken.id
  secret_data = var.YOUTUBE_AUTH_TOKEN
}
