variable "provider_credentials" {
  type = object({
    name        = string
    endpoint    = string
    api_token   = optional(string)
    username    = optional(string)
    password    = optional(string)
    insecure    = optional(bool, false)
    private_key = optional(string)
  })
}

variable "gluekube_docker_image" {
  type    = string
  default = "ghcr.io/glueops/gluekube"
}

variable "gluekube_docker_tag" {
  type    = string
  default = "v0.0.15-rc9"
}


variable "bastion" {
  description = "Bastion configuration."
  type = object({
    waggle_slot_name = string
  })
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
      aws_access_key_id     = string
      aws_secret_access_key = string
      aws_region            = string
      domain_name           = string
      zone_id               = string
      credential_id         = string
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
    cores                  = optional(number)
    memory                 = optional(number)
    disk_size              = optional(number)
    kubernetes_labels      = optional(map(string), {})
    kubernetes_annotations = optional(map(string), {})
    kubernetes_taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    available_nodes  = list(string)
    attached         = optional(bool, true)
    ballooning       = optional(bool, true)
    waggle_slot_name = optional(string)

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