variable "provider_credentials" {
  type = object({
    name        = string
    endpoint    = string
    api_token   = optional(string)
    insecure    = optional(bool, false)
    private_key = optional(string) # removed in 0.6.0; kept only to reject it
  })

  validation {
    condition     = var.provider_credentials.private_key == null
    error_message = "provider_credentials.private_key was removed in 0.6.0: the module no longer uses SSH. Delete it. If a pool or the bastion still uses cloud-init snippets, go back to 0.5.x and move them to cloud_init = \"iso\" first."
  }
}

variable "gluekube_docker_image" {
  type    = string
  default = "ghcr.io/glueops/gluekube"
}

variable "gluekube_docker_tag" {
  type    = string
  default = "v1.34.11-gluekube.9"
}


variable "bastion" {
  description = "Bastion configuration."
  type = object({
    create           = optional(bool, true)
    waggle_slot_name = string
    cloud_init       = optional(string) # removed in 0.6.0; kept only to reject it
  })

  validation {
    condition     = var.bastion.cloud_init == null
    error_message = "bastion.cloud_init was removed in 0.6.0: the bastion always boots from a seed ISO. Delete it."
  }
}

variable "autoglue" {
  description = "Configuration for the AutoGlue platform integration, including cluster naming, credentials, and Route53 DNS settings."
  type = object({
    autoglue_cluster_name = string

    credentials = object({
      autoglue_key        = string
      autoglue_org_secret = string
      base_url            = string
    })

    route_53_config = object({
      aws_region    = string
      domain_name   = string
      zone_id       = string
      credential_id = string
    })
  })
}

variable "proxmox_config" {
  description = "Proxmox infrastructure configuration including network bridges."
  type = object({
    networks = object({
      public = object({
        name = string
      })
      private = object({
        name    = string
        vlan_id = optional(number)
      })
      nat = object({
        name    = string
        vlan_id = optional(number)
      })
    })
  })
}

variable "node_pools" {
  type = list(object({
    name                   = string
    node_count             = number
    role                   = string
    subnet                 = optional(string, "public")
    kubernetes_labels      = optional(map(string), {})
    kubernetes_annotations = optional(map(string), {})
    kubernetes_taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    attached         = optional(bool, true)
    waggle_slot_name = string
    cloud_init       = optional(string) # removed in 0.6.0; kept only to reject it
  }))

  validation {
    condition     = length([for np in var.node_pools : np if np.role == "master" && np.attached]) > 0
    error_message = "At least one node pool must have role = 'master' and attached = true."
  }

  validation {
    condition     = alltrue([for np in var.node_pools : contains(["master", "worker"], np.role)])
    error_message = "Each node pool role must be either 'master' or 'worker'."
  }

  validation {
    condition     = alltrue([for np in var.node_pools : contains(["public", "private"], np.subnet)])
    error_message = "Each node pool subnet must be either 'public' or 'private'."
  }

  validation {
    condition     = alltrue([for np in var.node_pools : np.cloud_init == null])
    error_message = "node_pools[*].cloud_init was removed in 0.6.0: every pool boots from a seed ISO. Delete it."
  }

  validation {
    # The pool name is part of the seed ISO's name, which Proxmox only keeps as is with these characters.
    condition     = alltrue([for np in var.node_pools : can(regex("^[A-Za-z0-9_.-]+$", np.name))])
    error_message = "Node pool names may only use letters, digits, '.', '_' and '-'."
  }

}

variable "cluster_metadata" {
  type = object({
    calico_network_calico_cidr = string
    network_service_cidr       = string
    cloud                      = string
    cloud_vars                 = optional(map(string), {}) # Holds the cloud-specific overrides
  })
  description = <<-EOT
    Structured cluster metadata passed through to the autoglue-metadata module. All fields are required unless noted:
      - calico_network_calico_cidr: CIDR block for the Calico pod network (e.g. "10.244.0.0/16").
      - network_service_cidr:       CIDR block for Kubernetes services (e.g. "10.96.0.0/12").
      - cloud:                      Target cloud provider. One of: "aws", "proxmox", "hetzner".
      - cloud_vars:                 Optional map of cloud-specific overrides. When cloud is "proxmox",
                                    "calico_node_address_autodetection_v4" is required.
  EOT
}

variable "waggle_endpoint" {
  type    = string
  default = null
}

variable "waggle_api_key" {
  type    = string
  default = null
}

variable "waggle_datacenter_id" {
  type    = string
  default = null
}
