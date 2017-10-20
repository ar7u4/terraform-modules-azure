module "resource_group" {
  source   = "git::ssh://git@github.com/mobilabsolutions/terraform-modules.git?ref=1.2.0//modules/azurerm/resource_group"
  name     = "${var.name}"
  location = "${var.location}"
  tags     = "${var.tags}"
}

module "load_balancer" {
  source              = "git::ssh://git@github.com/mobilabsolutions/terraform-modules.git?ref=1.2.0//modules/azurerm/load_balancer/public"
  name                = "${var.name}"
  location            = "${var.location}"
  resource_group_name = "${module.resource_group.name}"
  rule_list           = "${var.load_balancing_rules}"
  tags                = "${var.tags}"
}

module "network" {
  source                 = "git::ssh://git@github.com/mobilabsolutions/terraform-modules.git?ref=1.2.0//modules/azurerm/network"
  name                   = "${var.name}"
  location               = "${var.location}"
  resource_group_name    = "${module.resource_group.name}"
  address_space          = "${var.address_space}"
  subnets                = "${var.subnets}"
  count                  = "${var.count}"
  lb_pool_ids            = "${list(module.load_balancer.backend_pool_id)}"
  rule_list              = "${var.network_security_rules}"
  virtual_network_tags   = "${var.virtual_network_tags}"
  security_group_tags    = "${var.security_group_tags}"
  network_interface_tags = "${var.network_interface_tags}"
}

module "availability_set" {
  source              = "git::ssh://git@github.com/mobilabsolutions/terraform-modules.git?ref=1.2.0//modules/azurerm/availability_set"
  name                = "${var.name}"
  resource_group_name = "${module.resource_group.name}"
}

module "storage_account" {
  source                   = "git::ssh://git@github.com/mobilabsolutions/terraform-modules.git?ref=1.2.0//modules/azurerm/storage/account"
  account_name             = "${var.name}"
  location                 = "${var.location}"
  account_tier             = "${var.account_tier}"
  account_replication_type = "${var.account_replication_type}"
  resource_group_name      = "${module.resource_group.name}"
  tags                     = "${var.tags}"
}

module "virtual_machine" {
  source                        = "git::ssh://git@github.com/mobilabsolutions/terraform-modules.git?ref=1.2.0//modules/azurerm/virtual_machine"
  name                          = "${var.name}"
  location                      = "${var.location}"
  resource_group_name           = "${module.resource_group.name}"
  storage_account_name          = "${module.storage_account.name}"
  storage_primary_blob_endpoint = "${module.storage_account.primary_blob_endpoint}"
  count                         = "${var.count}"
  network_security_group_id     = "${module.network.network_security_group_id}"
  availability_set_id           = "${module.availability_set.id}"
  lb_pool_ids                   = "${list(module.load_balancer.backend_pool_id)}"
  vm_size                       = "${var.vm_size}"
  image_publisher               = "${var.image_publisher}"
  image_offer                   = "${var.image_offer}"
  image_sku                     = "${var.image_sku}"
  image_version                 = "${var.image_version}"
  os_disk_name                  = "${var.os_disk_name}"
  public_key                    = "${var.public_key}"
  cloud_init_rendered           = "${var.cloud_init_rendered}"
  tags                          = "${var.tags}"
}
