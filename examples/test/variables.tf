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
    cores            = optional(number)
    memory           = optional(number)
    disk_size        = optional(number)
    proxmox_node     = optional(string)
    waggle_slot_name = optional(string)
  })
}

################################
# AutoGlue integration
################################
variable "autoglue_cluster_name" {
  type        = string
  description = "Cluster name to register in AutoGlue."
}

variable "autoglue_key" {
  type        = string
  description = "AutoGlue org key."
  sensitive   = true
}

variable "autoglue_org_secret" {
  type        = string
  description = "AutoGlue org secret."
  sensitive   = true
}

variable "autoglue_base_url" {
  type        = string
  description = "Base URL of the AutoGlue API."
}

################################
# Route53 config (AutoGlue captain domain)
################################
variable "route53_aws_access_key_id" {
  type        = string
  description = "AWS access key id used by AutoGlue for Route53 management."
  sensitive   = true
}

variable "route53_aws_secret_access_key" {
  type        = string
  description = "AWS secret access key used by AutoGlue for Route53 management."
  sensitive   = true
}

variable "route53_region" {
  type        = string
  description = "AWS region for the Route53 provider."
  default     = "us-west-2"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the captain domain."
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone id for the domain."
}

variable "autoglue_credential_id" {
  type        = string
  description = "AutoGlue credential id referencing the Route53 credentials."
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
