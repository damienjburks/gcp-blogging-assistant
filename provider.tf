terraform {
  cloud {
    organization = "DSB"

    workspaces {
      name = "terraform-starter"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}