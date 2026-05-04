resource "autoglue_ssh_key" "ssh_key" {
  name    = "${var.cluster_name}-${var.name}"
  comment = "GlueKube ${var.role} SSH Key"
}

resource "proxmox_virtual_environment_file" "node_cloud_init" {
  for_each     = toset([for i in range(0, var.node_count) : tostring(i)])
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloudinit/cloud-init-${var.role}.yaml", {
      public_key = autoglue_ssh_key.ssh_key.public_key
      hostname   = "${var.role}-${var.name}-${each.key}"
    })
    file_name = "${var.cluster_name}-${var.role}-${var.name}-${each.key}-cloud-init.yaml"
  }
}


# resource "proxmox_download_file" "ubuntu_noble_img" {
#   content_type       = "iso"
#   datastore_id       = "local"
#   file_name          = "noble-server-cloudimg-amd64.img"
#   node_name          = var.proxmox_node
#   url                = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
#   overwrite          = true
# }


resource "proxmox_virtual_environment_vm" "cluster_node" {
  for_each  = toset([for i in range(0, var.node_count) : tostring(i)])
  name      = "${var.role}-${var.name}-${each.key}"
  node_name = var.proxmox_node

  description = "GlueKube ${var.role} node - ${var.name}-${each.key}"

  machine       = "q35"
  bios          = "ovmf"

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
    floating  = var.memory / 2
  }

  disk {
    datastore_id = var.datastore_id
    import_from = "local:import/noble-server-cloudimg-amd64.qcow2"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
  }

  efi_disk {
    datastore_id = "local"
    file_format  = "qcow2"
    type         = "4m"
  }

  initialization {
    datastore_id = var.datastore_id
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    dynamic "ip_config" {
      for_each = var.subnet == "public" ? [1] : []
      content {
        ipv4 {
          address = "dhcp"
        }
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.node_cloud_init[each.key].id

    user_account {
      password = "changeme"
      username = "ubuntu"
    }
  }
  
  dynamic "network_device" {
    for_each = var.subnet == "public" ? [1] : []
    content {
      bridge = "vmbr_lan"
    }
  }

  network_device {
    bridge = var.subnet == "public" ? "vmbr_public" : "vmbr_nat"
  }

  

  agent {
    enabled = true
    timeout = "15m"
  }

  started = true

  startup {
    order      = 1
    up_delay   = 60
    down_delay = 0
  }

 
  
}
