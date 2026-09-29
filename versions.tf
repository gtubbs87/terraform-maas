terraform {
  required_version = ">= 1.5.0"

  required_providers {
    maas = {
      source  = "canonical/maas"
      version = "~> 2.0"
    }
  }

  # Keep state somewhere shared and locked once more than one person runs this.
  # MAAS state contains BMC credentials (power_parameters), so the backend must
  # be encrypted at rest and access-controlled. Example:
  #
  # backend "s3" {
  #   bucket         = "my-tf-state"
  #   key            = "maas/datacenter-1.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "tf-locks"
  #   encrypt        = true
  # }
}
