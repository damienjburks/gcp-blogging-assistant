# DSB Blogging Assistant

![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-purple?logo=terraform)  
![Python Requirements](https://img.shields.io/badge/python-3.12-blue?logo=python)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## Overview

The DSB Blogging Assistant is a framework designed to automate the creation of blog posts based on YouTube videos, streamlining the content creation process. It integrates several tools and technologies to simplify workflow automation.

This framework leverages:

- **Google Cloud Platform (GCP):** Utilizing various services such as Workflows, Cloud Functions, etc.
- **Docker:** Containerized applications deployed to AWS for hosting and management.
- **Terraform Cloud:** Infrastructure as Code (IaC) for deploying resources into AWS.
- **Python 3.12:** Custom code for the YouTube Poller and the core Lambda function that interacts with ChatGPT.

## Architecture Diagrams and Flows

### Base-Level Architecture Diagram

![Base Architecture Diagram](./docs/images/architecture.drawio.svg)

#### Explanation

### Use Case Architecture Flow Diagram

![Flow Diagram](./docs/images/flow.drawio.svg)

#### Flow Diagram Overview

1. A new video is uploaded to Damien's YouTube channel.
2. Damien logs into his console, and triggers the Workflow by passing in the following parameters:
   - videoName
   - videoUrl
3. The Workflow initiates the Cloud Function function, executing a series of steps:
   - **Step 1:** The video transcript is downloaded.
   - **Step 2:** The transcript is sent to ChatGPT with a request to generate a blog post in markdown format.
   - **Step 3:** The `dsb-digest` repository is cloned, and the new blog post is committed to a new branch based on a hashed value of the video title.
   - **Final Step:** The process concludes, and the final payload is sent to the SNS topic.
4. An email is sent to Damien with details about the new blog post in the `dsb-digest` repository.

## Terraform Launch Instructions

### Prerequisites

1. **Terraform Installed**: Ensure that you have Terraform installed on your local machine. You can download it from [Terraform's official website](https://www.terraform.io/downloads).
2. **Google Cloud SDK**: Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) to manage GCP resources and configure access locally.
3. **Google Cloud Credentials**: Set up service account credentials to authenticate Terraform with Google Cloud. [See this guide](https://cloud.google.com/docs/authentication/getting-started) for creating a service account with the necessary roles.

### Step 1: Create Organization and Configure Variables in Terraform Cloud

1. **Create Terraform Cloud Organization**:

   - Go to [Terraform Cloud](https://app.terraform.io/) and log into your account.
   - Navigate to **Settings > Organizations** and create a new organization.
   - Provide an organization name and email. You can select your preferred plan, or use the free tier.

2. **Create a Workspace**:

   - Under your newly created organization, go to **Workspaces > Create Workspace**.
   - Name the workspace `gcp-dsb-blogging-assistant`.
   - Choose the **Version Control Workflow** if you are connecting this to a GitHub repository, or the **CLI-driven Workflow** if you plan to manage it via the Terraform CLI.

3. **Set Workspace Variables**:
   - After creating the workspace, navigate to **Settings > Variables**.
   - Add the `GOOGLE_APPLICATION_CREDENTIALS` variable to your workspace to authenticate with GCP if you’re using a service account key.

### Step 2: Initialize Terraform

In the directory containing your Terraform configuration, run:

```bash
terraform init
```

This command initializes the working directory by installing the necessary provider plugins (in this case, the Google provider) and configuring Terraform Cloud.

### Step 3: Plan the Deployment

Once initialized, run the following command to generate and review the execution plan:

```bash
terraform plan
```

Terraform will display the resources it plans to create or modify. Review the output carefully to ensure everything is set up correctly.

### Step 4: Apply the Deployment

If everything looks good, apply the changes by running:

```bash
terraform apply
```

Terraform will prompt you to confirm the execution plan. Type `yes` to proceed, and Terraform will create the necessary GCP resources.

### Step 5: Monitor and Verify

Once the apply command finishes, you can verify the resources have been successfully created by checking the GCP Console. Navigate to the relevant project and confirm the resources are live.

### Example Configuration

Here is the complete Terraform configuration for reference:

```hcl
terraform {
  cloud {
    organization = "your_organization"

    workspaces {
      name = "gcp-dsb-blogging-assistant"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
```

### Optional: Terraform Cloud Workflow Automation

You can also automate runs in Terraform Cloud by linking your version control system (e.g., GitHub) to trigger Terraform runs whenever changes are pushed to the repository containing your Terraform code.

## References

- YouTube Push Notifications: <https://developers.google.com/youtube/v3/guides/push_notifications>
- Related project: <https://github.com/BryanCuneo/yt-to-discord/tree/main?tab=readme-ov-file>
- Parent project: <https://github.com/The-DevSec-Blueprint/dsb-blogging-assistant>

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
