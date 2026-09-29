locals {
  # Every tag used by any host -> hosts that carry it.
  tag_members = {
    for tag in distinct(flatten([for h in values(var.hosts) : h.tags])) :
    tag => [for name, h in var.hosts : name if contains(h.tags, tag)]
  }
}

module "host" {
  source   = "./modules/maas-host"
  for_each = var.hosts

  hostname = each.key
  register = each.value.register
  deploy   = each.value.deploy

  # Enlist + commission
  power_type            = coalesce(each.value.power_type, var.defaults.power_type)
  power_parameters      = merge(each.value.power_parameters, lookup(var.power_secrets, each.key, {}))
  pxe_mac_address       = each.value.pxe_mac_address
  architecture          = coalesce(each.value.architecture, var.defaults.architecture)
  zone                  = try(coalesce(each.value.zone, var.defaults.zone), null)
  pool                  = try(coalesce(each.value.pool, var.defaults.pool), null)
  domain                = try(coalesce(each.value.domain, var.defaults.domain), null)
  min_hwe_kernel        = each.value.min_hwe_kernel
  commissioning_scripts = each.value.commissioning_scripts
  testing_scripts       = each.value.testing_scripts
  commission_timeout    = var.defaults.commission_timeout

  # Deploy
  distro_series      = coalesce(each.value.distro_series, var.defaults.distro_series)
  hwe_kernel         = try(coalesce(each.value.hwe_kernel, var.defaults.hwe_kernel), null)
  network_interfaces = each.value.network_interfaces
  deploy_timeout     = var.defaults.deploy_timeout
  erase_on_release   = var.defaults.erase_on_release

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname            = each.key
    ssh_authorized_keys = var.ssh_authorized_keys
    packages            = var.extra_packages
    extra_runcmd        = each.value.extra_runcmd
  })

  # Subnets managed here must exist before a host tries to link to them.
  depends_on = [maas_subnet.this, maas_subnet_ip_range.reserved]
}

# Tags attach as soon as the machine exists in MAAS (they depend only on the
# machine, not the deployment), so they can be used for grouping, kernel_opts
# and allocation queries.
resource "maas_tag" "this" {
  for_each = local.tag_members

  name     = each.key
  machines = [for name in each.value : module.host[name].machine_ref]
}
