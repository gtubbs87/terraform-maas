# Credentials can come from variables or from the MAAS_API_URL / MAAS_API_KEY
# environment variables. Leave the variables null to use the environment.
provider "maas" {
  api_version = "2.0"
  api_url     = var.maas_api_url
  api_key     = var.maas_api_key

  installation_method      = var.maas_installation_method
  tls_ca_cert_path         = var.maas_tls_ca_cert_path
  tls_insecure_skip_verify = var.maas_tls_insecure_skip_verify
}
