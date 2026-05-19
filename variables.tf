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

variable "datastore_id" {
  type        = string
  description = "The Proxmox datastore ID for VM disks"
  default     = "local"
}

variable "calico_network_calico_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.calico_network_calico_cidr))
    error_message = "calico_network_calico_cidr must be a valid IPv4 CIDR block, for example: 172.16.0.0/16."
  }
}

variable "network_service_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.network_service_cidr))
    error_message = "network_service_cidr must be a valid IPv4 CIDR block for Kubernetes services, for example: 192.168.0.0/16."
  }
}

variable "calico_node_address_autodetection_v4" {
  type    = string
  default = null
  validation {
    condition     = var.calico_node_address_autodetection_v4 == null || can(cidrnetmask(var.calico_node_address_autodetection_v4))
    error_message = "calico_node_address_autodetection_v4 must be a valid IPv4 CIDR block, for example: 10.62.0.0/15."
  }
}

variable "bastion" {
  description = "Bastion configuration."
  type = object({
    cores        = number
    memory       = number
    disk_size    = number
    proxmox_node = string
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
    cores                  = number
    memory                 = number
    disk_size              = number
    role                   = string
    subnet                 = optional(string, "public")
    kubernetes_labels      = optional(map(string), {})
    kubernetes_annotations = optional(map(string), {})
    kubernetes_taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    attached        = optional(bool, true)
    ballooning      = optional(bool, true)
    available_nodes = list(string)
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
    condition     = alltrue([for np in var.node_pools : length(np.available_nodes) > 0])
    error_message = "Each node pool must have at least one node in available_nodes."
  }
}
