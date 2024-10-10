# DSB Blogging Assistant

![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-purple?logo=terraform)
![Python Requirements](https://img.shields.io/badge/python-3.12-blue?logo=python)

## Overview

The DSB Blogging Assistant is a framework designed to automate the creation of blog posts based on YouTube videos, streamlining the content creation process. It integrates several tools and technologies to simplify workflow automation.

This framework leverages:

- **Google Cloud Platform (GCP):** Utilizing various services such as Workflows, Cloud Functions, etc.
- **Docker:** Containerized applications deployed to AWS for hosting and management.
- **Terraform Cloud:** Infrastructure as Code (IaC) for deploying resources into AWS.
- **Python 3.12:** Custom code for the YouTube Poller and the core Lambda function that interacts with ChatGPT.

## Architecture Diagrams and Flows

### Base-Level Architecture Diagram

> **Note:** This diagram is outdated. The ALB has been decommissioned.  
> ![Base Architecture Diagram](./docs/images/architecture.drawio.svg)

#### Explanation

### Use Case Architecture Flow Diagram

![Flow Diagram](./docs/images/flow.drawio.svg)

#### Flow Diagram Overview

1. A new video is uploaded to Damien's YouTube channel.
2. Once published, the PubSubHubBub process sends an event to the ECS cluster's YouTube Poller service.
3. The poller extracts key information such as video title and URL, triggering a Step Function by passing the payload.
4. The Step Function initiates the Lambda function, executing a series of steps:
   - **Step 1:** The video transcript is downloaded.
   - **Step 2:** The transcript is sent to ChatGPT with a request to generate a blog post in markdown format.
   - **Step 3:** The `dsb-digest` repository is cloned, and the new blog post is committed to a new branch based on a hashed value of the video title.
   - **Final Step:** The process concludes, and the final payload is sent to the SNS topic.
5. An email is sent to Damien with details about the new blog post in the `dsb-digest` repository.

## Installation Instructions

## Engineering Notes

If you need to reconfigure your Terraform Cloud account or map it to your repository, refer to the following guide:  
<https://developer.hashicorp.com/terraform/tutorials/automation/github-actions>

## References

- YouTube Push Notifications: <https://developers.google.com/youtube/v3/guides/push_notifications>
- Related project: <https://github.com/BryanCuneo/yt-to-discord/tree/main?tab=readme-ov-file>

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
