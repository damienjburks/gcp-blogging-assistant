resource "google_workflows_workflow" "dsb_blog_assistant_workflow" {
  name            = "dsb-blogging-assistant-workflow"
  region          = "us-central1"
  service_account = google_service_account.dsb_blog_assistant_sa.email # Optional, replace with the actual service account if needed

  description = "Workflow for automating blog creation from YouTube videos."

  source_contents = <<-EOT
  main:
    steps:
    - getVideoInformation:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/getVideoId"
          body:
            videoName: $${videoName}
            videoUrl: $${videoUrl}
        result: videoInfo
    - isVideoShort:
        switch:
          - condition: $${videoInfo.isShort}
            next: ignoreShortVideo
          - next: sendVideoConfirmationEmail

    - ignoreShortVideo:
        return: "Video ignored because it is short."

    - sendVideoConfirmationEmail:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/sendConfirmationEmail"
          body:
            videoName: $${videoName}
            token: $${sys.task_token}
            ExecutionContext: $${sys.execution}
            processorLambdaFunctionUrl: $${YOUR_PROCESSOR_LAMBDA_FUNCTION_URL}
        result: emailResponse

    - isVideoTechnical:
        switch:
          - condition: $${emailResponse.Status == "Video is confirmed as technical!"}
            next: generateTechnicalBlogPost
          - next: generateNonTechnicalBlogPost

    - generateTechnicalBlogPost:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/generateBlogPost"
          body:
            videoName: $${videoName}
            videoType: "technical"
            videoId: $${videoInfo.videoId}
        result: technicalBlogPost
        next: publishBlogToGitHub

    - generateNonTechnicalBlogPost:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/generateBlogPost"
          body:
            videoName: $${videoName}
            videoType: "non-technical"
            videoId: $${videoInfo.videoId}
        result: nonTechnicalBlogPost
        next: publishBlogToGitHub

    - publishBlogToGitHub:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/commitBlogToGitHub"
          body:
            videoName: $${videoName}
            blogPostContents: $${technicalBlogPost.blogPostContents or nonTechnicalBlogPost.blogPostContents}
        result: commitResponse
        next: sendEmailToDSB

    - sendEmailToDSB:
        call: http.post
        args:
          url: "${google_cloudfunctions_function.processing_function.https_trigger_url}/sendEmail"
          body:
            commitId: $${commitResponse.commitId}
            branchName: $${commitResponse.branchName}
            videoName: $${videoName}
        result: emailResult
        return: emailResult
  EOT
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

resource "google_storage_bucket" "malicious_storage_bucket" {
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
  bucket = google_storage_bucket.malicious_storage_bucket.name
  source = data.archive_file.my_function_src.output_path
}

resource "google_cloudfunctions_function" "processing_function" {
  name                  = "dsb-blogging-assistant-processing-function"
  runtime               = "python312"
  entry_point           = "hello_world"
  source_archive_bucket = google_storage_bucket_object.src.bucket
  source_archive_object = google_storage_bucket_object.src.name

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.malicious_storage_bucket.name
  }

  https_trigger_security_level = "SECURE_ALWAYS"
}