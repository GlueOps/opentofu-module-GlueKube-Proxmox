data "waggle_slots" "available_slots" {
  name = var.waggle_slot_name
}

locals {
  cpu_cores = data.waggle_slots.available_slots.vcpu
  memory_mb = data.waggle_slots.available_slots.ram_gb * 1024
  disk_gb   = data.waggle_slots.available_slots.disk_gb

  # Deterministic per-cluster vm_id prefix derived from the captain domain (100-999).
  vm_id_prefix = 100 + parseint(substr(sha256(var.captain_domain), 0, 8), 16) % 900
}

module "waggle" {
  source               = "../waggle"
  pool_name            = "${var.cluster_name}-${var.name}-${var.role}"
  slot_id              = data.waggle_slots.available_slots.id
  desired_count        = var.node_count
  waggle_datacenter_id = var.waggle_datacenter_id
}

resource "autoglue_ssh_key" "ssh_key" {
  name    = "${var.cluster_name}-${var.name}"
  comment = "GlueKube ${var.role} SSH Key"
}


resource "proxmox_virtual_environment_file" "node_cloud_init" {
  for_each     = toset([for i in range(0, var.node_count) : tostring(i)])
  content_type = "snippets"
  datastore_id = "local"
  node_name    = module.waggle.nodes_placement_targets[each.key].node

  source_raw {
    data = templatefile("${path.module}/cloudinit/cloud-init.yaml", {
      public_key = autoglue_ssh_key.ssh_key.public_key
      hostname   = "${var.role}-${var.name}-${each.key}"
    })
    file_name = "${var.cluster_name}-${var.role}-${var.name}-${each.key}-cloud-init.yaml"
  }

  lifecycle {
    ignore_changes = [node_name, source_raw]
  }
}



resource "proxmox_virtual_environment_vm" "cluster_node" {
  for_each  = toset([for i in range(0, var.node_count) : tostring(i)])
  name      = "${var.role}-${var.name}-${each.key}"
  node_name = module.waggle.nodes_placement_targets[each.key].node

  description = "GlueKube ${var.role} node - ${var.name}-${each.key}"

  vm_id = local.vm_id_prefix * 500000 + (parseint(substr(sha256(var.name), 0, 8), 16) % 10000) * 50 + each.key

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = local.cpu_cores
    type  = "x86-64-v2-AES"
    numa  = true
  }

  memory {
    dedicated = local.memory_mb
    floating  = local.memory_mb
  }

  disk {
    datastore_id = "local"
    import_from  = "local:import/noble-server-cloudimg-amd64.qcow2"
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = local.disk_gb
  }

  efi_disk {
    datastore_id = "local"
    file_format  = "qcow2"
    type         = "4m"
  }

  initialization {
    datastore_id = "local"
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

  }

  dynamic "network_device" {
    for_each = var.subnet == "public" ? [1] : []
    content {
      bridge  = var.proxmox_config.networks.private.name
      model   = "virtio"
      vlan_id = var.proxmox_config.networks.private.vlan_id
    }
  }

  network_device {
    bridge  = var.subnet == "public" ? var.proxmox_config.networks.public.name : var.proxmox_config.networks.nat.name
    model   = "virtio"
    vlan_id = var.subnet == "public" ? null : var.proxmox_config.networks.nat.vlan_id
  }



  agent {
    enabled = true
    timeout = "15m"
  }

  started = true

  stop_on_destroy = true


  tags = [var.cluster_name, var.role, var.name]

  lifecycle {
    ignore_changes = [node_name, initialization, vm_id]
  }
}

resource "waggle_placements" "workers" {
  depends_on = [
    proxmox_virtual_environment_vm.cluster_node,
  ]
  for_each     = toset([for i in range(0, var.node_count) : tostring(i)])
  placement_id = module.waggle.nodes_placement_targets[each.key].placement
  vmid         = proxmox_virtual_environment_vm.cluster_node[each.key].vm_id

  lifecycle {
    ignore_changes = [placement_id]
  }
}
