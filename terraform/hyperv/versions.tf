terraform {
  required_version = ">= 1.13.0"

  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.0"
    }
  }
}

provider "hyperv" {
  user     = var.hyperv_user
  password = var.hyperv_password
  host     = var.hyperv_host
  port     = var.hyperv_port
  https    = var.hyperv_https
  insecure = var.hyperv_insecure
  use_ntlm = var.hyperv_use_ntlm
  timeout  = var.hyperv_timeout
}
