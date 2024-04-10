provider "pingone" {
  client_id      = var.pingone_client_id
  client_secret  = var.pingone_client_secret
  environment_id = var.pingone_environment_id
  region         = var.pingone_region

  global_options {
    environment {
      // This option should not be used in environments that contain production data.  Data loss may occur.
      production_type_force_delete = var.pingone_force_delete_environment
    }
    population {
      // This option should not be used in environments that contain production data.  Data loss may occur.
      contains_users_force_delete = var.pingone_force_delete_population
    }
  }
}

provider "davinci" {
  username       = var.pingone_username
  password       = var.pingone_password
  region         = var.pingone_region
  environment_id = var.pingone_environment_id
}