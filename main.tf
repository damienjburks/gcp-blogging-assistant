resource "google_workflows_workflow" "dsb_blog_assistant_workflow" {
  name            = "dsb-blogging-assistant-workflow"
  region          = "us-central1"
  service_account = google_service_account.dsb_blog_assistant_sa.email # Optional, replace with the actual service account if needed

  description = "Workflow for automating blog creation from YouTube videos."

  source_contents = <<-EOT
  main:
    params: [input]
    steps:
    - getVideoInformation:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/getVideoId"
          body:
            videoName: $${videoName}
            videoUrl: $${videoUrl}
    - returnOutput:
        return: $${getVideoInformation.json}
  EOT

  depends_on = [ google_cloudfunctions_function.processing_function ]
}

resource "google_service_account" "dsb_blog_assistant_sa" {
  account_id   = "dsb-blogging-assistant"
  display_name = "DSB Blogging Assistant Service Account"
}

resource "google_project_iam_binding" "workflow_sa_iam" {
  project = var.project_id
  role    = "roles/workflows.invoker"

  members = [
    "serviceAccount:${google_service_account.dsb_blog_assistant_sa.email}"
  ]
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
  name                  = "dsb-ba-processor"
  runtime               = "python310"
  entry_point           = "main"
  source_archive_bucket = google_storage_bucket_object.src.bucket
  source_archive_object = google_storage_bucket_object.src.name
  https_trigger_security_level = "SECURE_ALWAYS"
  trigger_http = true
}