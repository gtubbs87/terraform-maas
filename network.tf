# Optional: manage the provisioning network as code. Most sites already have
# fabrics/VLANs/subnets discovered by MAAS; in that case keep
# manage_network = false and just reference the subnet CIDR on each host.

resource "maas_fabric" "this" {
  count = var.manage_network ? 1 : 0
  name  = var.network.fabric_name
}

resource "maas_vlan" "this" {
  count  = var.manage_network ? 1 : 0
  fabric = maas_fabric.this[0].id
  vid    = var.network.vlan_vid
  name   = var.network.vlan_name
  mtu    = var.network.mtu
}

resource "maas_subnet" "this" {
  count       = var.manage_network ? 1 : 0
  cidr        = var.network.cidr
  fabric      = maas_fabric.this[0].id
  vlan        = maas_vlan.this[0].vid
  gateway_ip  = var.network.gateway_ip
  dns_servers = var.network.dns_servers
}

# Reserve ranges MAAS must never hand out (routers, switches, VIPs, ...).
resource "maas_subnet_ip_range" "reserved" {
  for_each = var.manage_network ? { for r in var.network.reserved_ranges : "${r.start_ip}-${r.end_ip}" => r } : {}

  subnet   = maas_subnet.this[0].id
  type     = "reserved"
  start_ip = each.value.start_ip
  end_ip   = each.value.end_ip
  comment  = each.value.comment
}
