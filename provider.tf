terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.103.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.2.1"
    }
    autoglue = {
      source  = "registry.terraform.io/GlueOps/autoglue"
      version = "0.10.12"
    }
  }
}

provider "proxmox" {
  endpoint  = var.provider_credentials.endpoint
  api_token = var.provider_credentials.api_token
  insecure  = var.provider_credentials.insecure
  ssh {
    agent       = false
    username    = "root"
    private_key = var.provider_credentials.private_key
  }
}

provider "autoglue" {
  base_url   = var.autoglue.credentials.base_url
  org_key    = var.autoglue.credentials.autoglue_key
  org_secret = var.autoglue.credentials.autoglue_org_secret
}

provider "aws" {
  alias      = "aws_route53"
  region     = var.autoglue.route_53_config.aws_region
  access_key = var.autoglue.route_53_config.aws_access_key_id
  secret_key = var.autoglue.route_53_config.aws_secret_access_key
}
