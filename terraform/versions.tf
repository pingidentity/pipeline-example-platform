terraform {
  required_version = ">= 1.6.0"
  required_providers {
    pingone = {
      source  = "pingidentity/pingone"
      version = ">= 0.27.0, < 1.0.0"
    }
    davinci = {
      source  = "pingidentity/davinci"
      version = ">= 0.2.1, < 1.0.0"
    }
  }
}