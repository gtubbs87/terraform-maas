output "system_id" {
  description = "MAAS system ID (null if the machine is neither enlisted nor deployed by Terraform)."
  value       = var.register ? maas_machine.this[0].id : (var.deploy ? maas_instance.this[0].id : null)
}

output "machine_ref" {
  description = "Identifier usable by other MAAS resources (system ID when enlisted here, else hostname)."
  value       = var.register ? maas_machine.this[0].id : var.hostname
}

output "stage" {
  description = "deployed | ready | unmanaged"
  value       = var.deploy ? "deployed" : (var.register ? "ready" : "unmanaged")
}

output "fqdn" {
  value = var.deploy ? maas_instance.this[0].fqdn : null
}

output "ip_addresses" {
  value = var.deploy ? tolist(maas_instance.this[0].ip_addresses) : []
}
