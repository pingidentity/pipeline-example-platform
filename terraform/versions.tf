terraform {
  required_version = ">= 1.6.0"
  required_providers {
    pingone = {
      source  = "pingidentity/pingone"
      version = ">= 1.1.1, < 2.0.0"
    }
    davinci = {
      source  = "pingidentity/davinci"
      version = "~> 0.4"
    }
  }
  backend "s3" {}
}