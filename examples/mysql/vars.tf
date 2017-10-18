variable azure_subscription_id {
  description = "Azure Subscription ID"
}

variable azure_client_id {
  description = "Azure Client ID"
}

variable azure_client_secret {
  description = "Azure Client Secret"
}

variable azure_tenant_id {
  description = "Azure Tenant ID"
}

variable name {
  type = "string"
}

variable location {
  type = "string"
}

variable administrator_login {
  type = "string"
}

variable administrator_login_password {
  type = "string"
}

variable ssl_enforcement {
  type = "string"
}

variable storage_mb {
  type = "string"
}

variable sql_firewall_rules {
  type = "list"
}
