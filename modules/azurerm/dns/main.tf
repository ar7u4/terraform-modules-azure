provider "azurerm" {
  version = "=2.20.0"
  features {}
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_dns_zone" "this" {
  name                = "${var.domain_prefix}.${var.domain_name}"
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = var.tags
}