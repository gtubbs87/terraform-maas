variable "hostname" {
  description = "Hostname in MAAS."
  type        = string
}

variable "register" {
  description = "Enlist the machine in MAAS (triggers commissioning). False = machine already exists in MAAS."
  type        = bool
  default     = true
}

variable "deploy" {
  description = "Allocate and deploy the machine. False = leave it Ready."
  type        = bool
  default     = true
}

# --- Enlistment / commissioning -------------------------------------------

variable "power_type" {
  description = "MAAS power driver: ipmi, redfish, virsh, lxd, webhook, manual, ..."
  type        = string
  default     = "ipmi"
}

variable "power_parameters" {
  description = "Power driver parameters (e.g. power_address, power_user, power_pass)."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "pxe_mac_address" {
  description = "MAC of the NIC the machine PXE boots from."
  type        = string
  default     = null
}

variable "architecture" {
  type    = string
  default = "amd64/generic"
}

variable "zone" {
  type    = string
  default = null
}

variable "pool" {
  type    = string
  default = null
}

variable "domain" {
  type    = string
  default = null
}

variable "min_hwe_kernel" {
  type    = string
  default = null
}

variable "commissioning_scripts" {
  description = "Commissioning scripts to run. Null = MAAS defaults (all custom scripts)."
  type        = list(string)
  default     = null
}

variable "testing_scripts" {
  description = "Hardware tests to run after commissioning. Null = scripts tagged 'testing'."
  type        = list(string)
  default     = null
}

variable "commission_timeout" {
  type    = string
  default = "45m"
}

# --- Deployment -------------------------------------------------------------

variable "distro_series" {
  description = "OS release to deploy, e.g. noble, jammy."
  type        = string
  default     = "noble"
}

variable "hwe_kernel" {
  type    = string
  default = null
}

variable "user_data" {
  description = "cloud-init user data. Changing it redeploys the machine."
  type        = string
  default     = null
}

variable "network_interfaces" {
  description = "Interface -> subnet/IP links configured before deployment."
  type = list(object({
    name        = string
    subnet_cidr = optional(string)
    ip_address  = optional(string)
  }))
  default = []
}

variable "deploy_timeout" {
  type    = string
  default = "45m"
}

variable "erase_on_release" {
  description = "Quick-erase disks when the machine is released (destroy / deploy=false)."
  type        = bool
  default     = false
}
