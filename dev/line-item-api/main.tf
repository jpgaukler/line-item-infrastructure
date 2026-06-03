# ============================================= Auth0 API =============================================
resource "auth0_resource_server" "api" {
  name        = "${local.api_name}-${local.environment_stage}"
  identifier  = local.api_audience
  signing_alg = "RS256"

  token_lifetime           = 86400 # 24 hours (in seconds)
  token_lifetime_for_web   = 7200  # 2 hours

  allow_offline_access                            = true
  skip_consent_for_verifiable_first_party_clients = true

  # Application Access Policy (AAP) settings to enforce "per-app authorization"
  subject_type_authorization {
    user {
      policy = "require_client_grant" 
    }
    client {
      policy = "require_client_grant" 
    }
  }
}

resource "auth0_resource_server_scopes" "api_scopes" {
  resource_server_identifier = auth0_resource_server.api.identifier

  scopes {
    name        = "read:products"
    description = "Read products"
  }

  scopes {
    name        = "write:products"
    description = "Create and modify products"
  }

  scopes {
    name        = "read:quotes"
    description = "Read quotes"
  }

  scopes {
    name        = "write:quotes"
    description = "Create and modify quotes"
  }
}

# authorize client application to access API 
resource "auth0_client_grant" "app_client" {
  client_id    = data.terraform_remote_state.line_item_app.outputs.auth0_client_id
  audience     = auth0_resource_server.api.identifier
  scopes       = []
  subject_type = "user"
}