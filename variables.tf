# ---------------------------------------------------------------------------
# MAAS connection
# ---------------------------------------------------------------------------

variable "maas_api_url" {
  description = "MAAS API URL, e.g. http://10.0.0.2:5240/MAAS. Null = read MAAS_API_URL."
  type        = string
  default     = null
}

variable "maas_api_key" {
  description = "MAAS API key (consumer:token:secret). Null = read MAAS_API_KEY."
  type        = string
  default     = null
  sensitive   = true
}

variable "maas_installation_method" {
  description = "How MAAS is installed: snap or deb."
  type        = string
  default     = "snap"

  validation {
    condition     = contains(["snap", "deb"], var.maas_installation_method)
    error_message = "maas_installation_method must be \"snap\" or \"deb\"."
  }
}

variable "maas_tls_ca_cert_path" {
  description = "CA bundle used to verify the MAAS TLS certificate."
  type        = string
  default     = null
}

variable "maas_tls_insecure_skip_verify" {
  description = "Skip TLS verification. Lab use only."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Optional network management (see network.tf)
# ---------------------------------------------------------------------------

variable "manage_network" {
  description = "Create the fabric/VLAN/subnet below. Leave false if MAAS networking is already set up."
  type        = bool
  default     = false
}

variable "network" {
  description = "Fabric, VLAN and subnet to create when manage_network = true."
  type = object({
    fabric_name = string
    vlan_vid    = number
    vlan_name   = optional(string)
    mtu         = optional(number, 1500)
    cidr        = string
    gateway_ip  = string
    dns_servers = optional(list(string), [])
    reserved_ranges = optional(list(object({
      start_ip = string
      end_ip   = string
      comment  = optional(string)
    })), [])
  })
  default = null
}

# ---------------------------------------------------------------------------
# Defaults applied to every host unless the host overrides them
# ---------------------------------------------------------------------------

variable "defaults" {
  description = "Default values for hosts."
  type = object({
    power_type         = optional(string, "ipmi")
    architecture       = optional(string, "amd64/generic")
    zone               = optional(string)
    pool               = optional(string)
    domain             = optional(string)
    distro_series      = optional(string, "noble")
    hwe_kernel         = optional(string)
    commission_timeout = optional(string, "45m")
    deploy_timeout     = optional(string, "45m")
    erase_on_release   = optional(bool, false)
  })
  default = {}
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys added to the default user via cloud-init (in addition to keys stored in the MAAS user profile)."
  type        = list(string)
  default     = []
}

variable "extra_packages" {
  description = "Packages installed on every deployed host via cloud-init."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Hosts
# ---------------------------------------------------------------------------

variable "hosts" {
  description = <<-EOT
    Map of hostname => host definition.

    register = true  : Terraform enlists the machine (maas_machine), which makes
                       MAAS commission it. Needs power_* and pxe_mac_address.
    register = false : The machine already exists in MAAS (e.g. auto-enlisted);
                       Terraform only allocates/deploys it by hostname.
    deploy   = true  : Allocate and deploy an OS (maas_instance).
    deploy   = false : Stop at "Ready" (commissioned, not deployed). Flipping
                       true -> false releases the machine.
  EOT

  type = map(object({
    register = optional(bool, true)
    deploy   = optional(bool, true)

    # Enlistment / commissioning (register = true)
    power_type            = optional(string)
    power_parameters      = optional(map(string), {}) # non-secret, e.g. power_address, power_user
    pxe_mac_address       = optional(string)
    architecture          = optional(string)
    zone                  = optional(string)
    pool                  = optional(string)
    domain                = optional(string)
    min_hwe_kernel        = optional(string)
    commissioning_scripts = optional(list(string))
    testing_scripts       = optional(list(string))

    # Deployment (deploy = true)
    distro_series = optional(string)
    hwe_kernel    = optional(string)
    network_interfaces = optional(list(object({
      name        = string           # interface name as discovered by commissioning, e.g. eno1
      subnet_cidr = optional(string) # must already exist in MAAS
      ip_address  = optional(string) # static IP; omit for AUTO assignment
    })), [])
    extra_runcmd  = optional(list(string), []) # extra shell commands run once at first boot

    tags = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for name, h in var.hosts : !h.register || h.pxe_mac_address != null || coalesce(h.power_type, "ipmi") == "ipmi"
    ])
    error_message = "Hosts with register = true need pxe_mac_address (only IPMI machines may omit it)."
  }
}

variable "power_secrets" {
  description = "Sensitive power parameters per host, merged over hosts[*].power_parameters. Example: { node01 = { power_pass = \"...\" } }"
  type        = map(map(string))
  default     = {}
  sensitive   = true
}
