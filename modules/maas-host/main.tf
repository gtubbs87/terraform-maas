terraform {
  required_providers {
    maas = {
      source = "canonical/maas"
    }
  }
}

# ---------------------------------------------------------------------------
# Stage 1: enlist + commission.
# Creating a maas_machine adds it to MAAS, which powers it on over the BMC,
# PXE boots the ephemeral image, runs commissioning (and testing) scripts and
# waits for the machine to reach "Ready".
# ---------------------------------------------------------------------------
resource "maas_machine" "this" {
  count = var.register ? 1 : 0

  hostname         = var.hostname
  domain           = var.domain
  zone             = var.zone
  pool             = var.pool
  architecture     = var.architecture
  min_hwe_kernel   = var.min_hwe_kernel
  power_type       = var.power_type
  power_parameters = jsonencode(var.power_parameters)
  pxe_mac_address  = var.pxe_mac_address

  commissioning_scripts = var.commissioning_scripts
  testing_scripts       = var.testing_scripts

  timeouts {
    create = var.commission_timeout
    update = var.commission_timeout
  }
}

# ---------------------------------------------------------------------------
# Stage 2: allocate + deploy.
# Destroying this resource (or setting deploy = false) releases the machine
# back to "Ready" without removing it from MAAS.
# ---------------------------------------------------------------------------
resource "maas_instance" "this" {
  count = var.deploy ? 1 : 0

  allocate_params {
    # Pin to the exact machine: by system ID if we enlisted it, else by hostname.
    system_id = var.register ? maas_machine.this[0].id : null
    hostname  = var.register ? null : var.hostname
    zone      = var.zone
    pool      = var.pool
  }

  deploy_params {
    distro_series = var.distro_series
    hwe_kernel    = var.hwe_kernel
    user_data     = var.user_data
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      name        = network_interfaces.value.name
      subnet_cidr = network_interfaces.value.subnet_cidr
      ip_address  = network_interfaces.value.ip_address
    }
  }

  release_params {
    erase       = var.erase_on_release
    quick_erase = var.erase_on_release
  }

  timeouts {
    create = var.deploy_timeout
    delete = var.deploy_timeout
  }
}
