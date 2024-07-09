resource "davinci_connection" "sso" {
  environment_id = pingone_environment.target_environment.id

  connector_id = "pingOneSSOConnector"
  name         = "PingOne"

  property {
    name  = "clientId"
    type  = "string"
    value = pingone_application.davinci_connection_worker.oidc_options[0].client_id
  }

  property {
    name  = "clientSecret"
    type  = "string"
    value = pingone_application.davinci_connection_worker.oidc_options[0].client_secret
  }

  property {
    name  = "envId"
    type  = "string"
    value = pingone_application.davinci_connection_worker.environment_id
  }

  property {
    name  = "region"
    type  = "string"
    value = "NA"
  }
}

resource "davinci_connection" "http" {
  environment_id = pingone_environment.target_environment.id
  name           = "Http"
  connector_id   = "httpConnector"
}