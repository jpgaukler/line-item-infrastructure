# =============================================
# Auth0 Resource Server (API)
# =============================================
resource "auth0_resource_server" "api_resource_server" {
  name        = "${var.api_name}-${var.environment_stage}"
  identifier  = var.api_audience
  signing_alg = "RS256"

  token_lifetime         = var.token_lifetime
  token_lifetime_for_web = var.token_lifetime_for_web

  allow_offline_access                            = true
  skip_consent_for_verifiable_first_party_clients = true

  enforce_policies = true                 // enable RBAC
  token_dialect    = "access_token_authz" // include permission claims in access token

  # Application Access Policy settings to enforce per-app authorization.
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
  resource_server_identifier = auth0_resource_server.api_resource_server.identifier

  dynamic "scopes" {
    for_each = var.api_scopes

    content {
      name        = scopes.value.name
      description = scopes.value.description
    }
  }
}

resource "auth0_client_grant" "app_clients" {
  for_each = var.client_grants

  client_id        = each.value.client_id
  audience         = auth0_resource_server.api_resource_server.identifier
  subject_type     = each.value.subject_type
  allow_all_scopes = each.value.allow_all_scopes
  scopes           = each.value.allow_all_scopes ? null : each.value.scopes
}

resource "auth0_role" "api_roles" {
  for_each = var.api_roles

  name        = each.value.name
  description = each.value.description
}
resource "auth0_role_permissions" "api_role_permissions" {
  for_each = var.api_roles

  role_id = auth0_role.api_roles[each.key].id

  dynamic "permissions" {
    for_each = toset(each.value.permissions)

    content {
      name                       = permissions.value
      resource_server_identifier = auth0_resource_server.api_resource_server.identifier
    }
  }
  
  depends_on = [auth0_resource_server_scopes.api_scopes]
}

resource "auth0_action" "append_custom_claims" {
  name    = "Append Custom Claims"
  runtime = "node22"
  deploy  = true

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }

  code = <<-EOT
  exports.onExecutePostLogin = async (event, api) => {
    const namespace = '${var.custom_claims_namespace}';

    if (event.authorization) {
      api.accessToken.setCustomClaim(`$${namespace}/name`, event.user.name);
    }
  };
  EOT
}

resource "auth0_trigger_actions" "post_login" {
  trigger = "post-login"

  actions {
    id           = auth0_action.append_custom_claims.id
    display_name = auth0_action.append_custom_claims.name
  }
}
