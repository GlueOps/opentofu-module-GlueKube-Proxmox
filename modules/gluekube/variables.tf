variable "proxmox_config" {
  description = "Proxmox infrastructure configuration including network bridges."
  type = object({
    networks = object({
      public = object({
        name = string
      })
      private = object({
        name = string
        vlan_id = optional(number)

      })
      nat = object({
        name = string
        vlan_id = optional(number)
      })
    })
  })
}

variable "subnet" {
  type        = string
  description = "The subnet type: 'public' maps to vmbr_public, 'private' maps to vmbr_lan"
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.subnet)
    error_message = "subnet must be either 'public' or 'private'."
  }
}

variable "node_count" {
  type    = number
  default = 1
}

variable "role" {
  type = string
}

variable "kubernetes_labels" {
  type = map(string)
}

variable "kubernetes_annotations" {
  type = map(string)
}

variable "kubernetes_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "attached" {
  type = bool
}

variable "datastore_id" {
  type        = string
  description = "The Proxmox datastore ID for container disks"
}

variable "ballooning" {
  type        = bool
  description = "Enable memory ballooning for this node pool"
  default     = true
}

variable "available_nodes" {
  type        = list(string)
  description = "List of available Proxmox node names for scheduling VMs"
}

variable "waggle_datacenter_id" {
  type = string
}

variable "waggle_slot_name" {
  type = string
  default = "xlarge"
}