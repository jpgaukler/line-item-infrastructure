
module "auth0_api" {
  source = "../../../modules/auth0-api"

  environment_stage           = local.environment_stage
  api_name                    = local.api_name
  api_audience                = local.auth0_api_audience
  custom_claims_namespace     = "https://line-item.app"
  
  client_grants = {
    line_item_app = {
      client_id        = data.terraform_remote_state.line_item_app.outputs.auth0_client_id
      subject_type     = "user"
      allow_all_scopes = true
    }
  }

  api_scopes = [
    {
      name        = "read:products"
      description = "Read products"
    },
    {
      name        = "write:products"
      description = "Create and modify products"
    },
    {
      name        = "read:quotes"
      description = "Read quotes"
    },
    {
      name        = "write:quotes"
      description = "Create and modify quotes"
    }
  ]

  api_roles = {
    administrator = {
      name        = "Administrator"
      description = "Full privileges"
      permissions = [
        "read:products",
        "write:products",
        "read:quotes",
        "write:quotes"
      ]
    }

    reader = {
      name        = "Reader"
      description = "Read-only access"
      permissions = [
        "read:products",
        "read:quotes"
      ]
    }
  }
}