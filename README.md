# Terraform + Canonical MAAS: commission and deploy bare metal

Declare your hosts in one map, and Terraform drives each one through the MAAS lifecycle:

```
 hosts["node01"]            maas_machine               maas_instance
 ───────────────►  New ──► Commissioning ──► Ready ──► Allocated ──► Deployed
                   (register = true)          │        (deploy = true)
                                               └── maas_tag applied here
```

| Setting | What Terraform does |
|---|---|
| `register = true` (default) | Creates `maas_machine`. MAAS powers the host on through its BMC, PXE-boots it, commissions and tests it, then waits for **Ready**. |
| `register = false` | Skips enlistment. Use this for machines MAAS already has, for example ones that PXE-booted and auto-enlisted. |
| `deploy = true` (default) | Creates `maas_instance`, which allocates the machine and deploys the OS with cloud-init, network links and the kernel you chose. |
| `deploy = false` | Leaves the host in **Ready**. Changing `true` → `false` **releases** the machine. |

## Layout

```
versions.tf                 provider pin (canonical/maas ~> 2.0) + backend stub
providers.tf                MAAS connection
variables.tf                inputs: connection, defaults, hosts, power_secrets
main.tf                     one module per host + tags
network.tf                  optional fabric/VLAN/subnet/reserved ranges
outputs.tf                  per-host system_id/fqdn/IPs + Ansible inventory
templates/cloud-init.yaml.tftpl
modules/maas-host/          maas_machine (commission) + maas_instance (deploy)
terraform.tfvars.example
```

## Prerequisites

- MAAS 3.x with boot images synced, and a rack controller that serves DHCP on the PXE VLAN.
- An API key: `sudo maas apikey --username <admin>`.
- For every host you register: BMC details (IPMI/Redfish/etc.) and the MAC address of its PXE NIC.
- Terraform 1.5 or later.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # edit hosts
export MAAS_API_URL=http://<maas>:5240/MAAS
export MAAS_API_KEY=<consumer:token:secret>
export TF_VAR_power_secrets='{"node01":{"power_pass":"..."}}'

terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output hosts
```

### Common workflows

- **Commission only, deploy later.** Set `deploy = false`, then apply. When the hardware looks good in MAAS, set it back to `true` and apply again.
- **Redeploy / reimage one host:** `terraform apply -replace='module.host["node01"].maas_instance.this[0]'`
- **Recommission one host:** `terraform apply -replace='module.host["node01"].maas_machine.this[0]'`. This deletes the machine from MAAS and enlists it again, which also redeploys it.
- **Release a host but keep it in MAAS:** set `deploy = false`.
- **Remove a host from MAAS completely:** delete it from `hosts`.
- **Adopt a machine that already exists:** use `terraform import 'module.host["node01"].maas_machine.this[0]' node01.maas`, or set `register = false`.

## Things to know

- **Changing a host's `user_data`, `distro_series` or `network_interfaces` redeploys that host.** Always read `terraform plan` before applying. For production hosts, think about adding `lifecycle { prevent_destroy = true }` to `maas_instance` in the module.
- **State contains your BMC passwords** (`power_parameters`). Use an encrypted remote backend with locking (see `versions.tf`). Never commit `*.tfstate` or `terraform.tfvars`.
- `network_interfaces[*].name` has to match the interface name that commissioning discovered (for example `eno1` or `enp1s0f0`). The subnet has to exist in MAAS already, or be created through `manage_network`.
- **Storage layout.** This template uses the storage layout that MAAS applies by default. For a custom layout (RAID, LVM, specific partitions), add `maas_block_device` / `maas_raid` resources to the module that reference `maas_machine.this[0].id`, and add `depends_on` to `maas_instance`.
- **Bonds and bridges.** Add `maas_network_interface_bond` / `_bridge` and `maas_network_interface_link` in the same way. They have to be applied while the machine is Ready, before `maas_instance`.
- **Tags** that `hosts[*].tags` references are created and owned by this configuration. If a tag with the same name already exists in MAAS, the apply fails.
- Commissioning and deployment can take a long time on some hardware. Raise `defaults.commission_timeout` / `deploy_timeout` if they time out.
