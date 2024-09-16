data "google_project" "default" {}

resource "google_workflows_workflow" "dsb_blog_assistant_workflow" {
  name        = "dsb-blogging-assistant-workflow"
  region      = "us-central1"
  description = "Workflow for automating blog creation from YouTube videos."

  source_contents = <<-EOT
  main:
    params: [input]
    steps:
    - generateBlogPost:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/generateBlogPost"
          body:
            videoName: $${input.videoName}
            videoUrl: $${input.videoUrl}
          auth:
            type: OIDC
        result: generateBlogPostResult

    - returnOutput:
        return: $${generateBlogPostResult.body}
  EOT

  depends_on = [google_cloudfunctions_function.processing_function]
}

resource "google_storage_bucket" "default" {
  name          = "dsb-blogging-assistant-storage"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
}

data "archive_file" "my_function_src" {
  type             = "zip"
  source_dir       = "${path.module}/src"
  output_file_mode = "0666"
  output_path      = "${path.module}/dsb_ba_function_src.zip"
}

resource "google_storage_bucket_object" "src" {
  name   = "${data.archive_file.my_function_src.output_md5}.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.my_function_src.output_path
}

resource "google_cloudfunctions_function" "processing_function" {
  name        = "dsb-ba-processor"
  runtime     = "python312"
  entry_point = "main"

  source_archive_bucket        = google_storage_bucket_object.src.bucket
  source_archive_object        = google_storage_bucket_object.src.name
  https_trigger_security_level = "SECURE_ALWAYS"
  ingress_settings             = "ALLOW_ALL"
  trigger_http                 = true

  environment_variables = {
    "OPENAI_TOKEN_ID"      = google_secret_manager_secret.openai_authtoken.secret_id
    "YOUTUBE_TOKEN_ID"     = google_secret_manager_secret.youtube_authtoken.secret_id
    "GIT_USERNAME_ID"      = google_secret_manager_secret.git_username.secret_id
    "GIT_TOKEN_ID"         = google_secret_manager_secret.git_authtoken.secret_id
    "REPOSITORY_URL"       = "https://github.com/The-DevSec-Blueprint/dsb-digest"
    "YOUTUBE_CHANNEL_NAME" = "Damien Burks | The DevSec Blueprint (DSB)"
    "PROJECT_ID"           = var.project_id
    "PROJECT_NUMBER"       = data.google_project.default.number
  }

  depends_on = [
    google_secret_manager_secret.git_authtoken,
    google_secret_manager_secret.git_username,
    google_secret_manager_secret.openai_authtoken,
    google_secret_manager_secret.youtube_authtoken,
    google_storage_bucket_object.src
  ]
}

resource "google_cloudfunctions_function_iam_member" "workflow_invoker" {
  project        = google_cloudfunctions_function.processing_function.project
  region         = google_cloudfunctions_function.processing_function.region
  cloud_function = google_cloudfunctions_function.processing_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"

  depends_on = [google_cloudfunctions_function.processing_function]
}

resource "google_project_iam_member" "secretmanager_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor" # Role that grants access to Secret Manager
  member  = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"

  depends_on = [google_cloudfunctions_function.processing_function]
}
