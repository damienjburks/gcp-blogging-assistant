terraform {
  cloud {
    organization = "DSB"

    workspaces {
      name = "gcp-dsb-blogging-assistant"
    }
  }
}