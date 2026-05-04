variable "proxmox_node" {
  type        = string
  description = "The Proxmox node name to deploy VMs on"
}

variable "datastore_id" {
  type        = string
  description = "The Proxmox datastore ID for container disks"
}

variable "cores" {
  type        = number
  description = "Number of CPU cores per node"
}

variable "memory" {
  type        = number
  description = "Memory in MB per node"
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB per node"
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
