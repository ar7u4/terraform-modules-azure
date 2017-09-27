resource "azurerm_public_ip" "pi" {
  count = "${var.count}"

  # Resource location
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  # Public IP Information
  name                         = "${lower(var.name)}-ip-vm-${format(var.count_format, var.count_offset + count.index + 1)}"
  domain_name_label            = "${lower(var.name)}-${format(var.count_format, var.count_offset + count.index + 1)}"
  public_ip_address_allocation = "dynamic"

  tags = "${merge(var.tags, map("resourceType", "pi"))}"
}

# All VMs require a network interface
resource "azurerm_network_interface" "ni" {
  count = "${var.count}"

  # Resource location
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  # NIC Name Information
  name                      = "${var.name}-ni-vm-${format(var.count_format, var.count_offset + count.index + 1)}"
  internal_dns_name_label   = "${var.name}-${format(var.count_format, var.count_offset + count.index + 1)}"
  network_security_group_id = "${var.network_security_group_id}"

  ip_configuration {
    name                                    = "${var.name}-${format(var.count_format, var.count_offset + count.index + 1)}"
    subnet_id                               = "${lookup("${var.subnet_ids}","${var.subnet_cidr}")}"
    private_ip_address_allocation           = "${var.private_ip_address_allocation}"
    public_ip_address_id                    = "${element(azurerm_public_ip.pi.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${compact(var.lb_pool_ids)}"]
  }

  tags = "${merge(var.tags, map("resourceType", "ni"))}"
}

resource "azurerm_storage_container" "osdisk" {
  count                 = "${var.count}"
  name                  = "${var.name}-${format(var.count_format, var.count_offset + count.index + 1)}"
  storage_account_name  = "${var.storage_account_name}"
  resource_group_name   = "${var.resource_group_name}"
  container_access_type = "private"
}

data "template_file" "init" {
  template = "${var.cloud_init}"

  vars {
    ssh_users      = "${var.ssh_users}"
    azure_sa_name  = "${var.azure_sa_name}"
    azure_sa_key   = "${var.azure_sa_key}"
    driver_version = "${var.driver_version}"
    rancher_host   = "${var.rancher_host}"
  }
}

resource "azurerm_virtual_machine" "vm" {
  count                 = "${var.count}"
  name                  = "${var.name}-vm-${format(var.count_format, var.count_offset + count.index + 1)}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.ni.*.id, count.index)}"]
  vm_size               = "${var.vm_size}"
  availability_set_id   = "${var.availability_set_id}"

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name          = "${var.name}-${format(var.count_format, var.count_offset + count.index + 1)}"
    vhd_uri       = "${var.storage_primary_blob_endpoint}${element(azurerm_storage_container.osdisk.*.name, count.index)}/${var.os_disk_name}.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.name}-${format(var.count_format, var.count_offset+count.index+1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${uuid()}"
    custom_data    = "${data.template_file.init.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.public_key}"
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${var.storage_primary_blob_endpoint}"
  }

  tags = "${merge(var.tags, map("resourceType", "vm"))}"
}
