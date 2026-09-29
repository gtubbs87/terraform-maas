output "hosts" {
  description = "Per-host MAAS system ID, lifecycle stage, FQDN and IPs."
  value = {
    for name, h in module.host : name => {
      system_id    = h.system_id
      stage        = h.stage
      fqdn         = h.fqdn
      ip_addresses = h.ip_addresses
    }
  }
}

output "ansible_inventory" {
  description = "Deployed hosts in a simple INI inventory format."
  value = join("\n", concat(["[maas_deployed]"], [
    for name, h in module.host : "${name} ansible_host=${h.ip_addresses[0]}"
    if h.stage == "deployed" && length(h.ip_addresses) > 0
  ]))
}
