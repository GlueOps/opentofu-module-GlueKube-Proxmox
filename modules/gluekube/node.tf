resource "random_shuffle" "available_nodes" {
  input        = var.available_nodes
  result_count = length(var.available_nodes)
}

locals {
  vm_node_name_by_index = {
    for i in range(0, var.node_count) :
    tostring(i) => random_shuffle.available_nodes.result[i % length(random_shuffle.available_nodes.result)]
  }
}



resource "proxmox_virtual_environment_vm" "cluster_node" {
  for_each  = toset([for i in range(0, var.node_count) : tostring(i)])
  name      = "${var.cluster_name}-${var.role}-${var.name}-${each.key}"
  node_name = local.vm_node_name_by_index[each.key]

  description = "GlueKube ${var.role} node - ${var.name}-${each.key}"

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
    numa  = true
  }

  memory {
    dedicated = var.memory
    floating  = var.ballooning ? var.memory / 2 : var.memory
  }

  disk {
    datastore_id = var.datastore_id
    import_from  = "local:import/noble-server-cloudimg-amd64.qcow2"
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

    user_data_file_id = var.cloud_init_file_ids_by_node[local.vm_node_name_by_index[each.key]]

  }

  lifecycle {
    precondition {
      condition     = contains(keys(var.cloud_init_file_ids_by_node), local.vm_node_name_by_index[each.key])
      error_message = "Missing shared cloud-init file id for selected Proxmox node."
    }
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

}


resource "proxmox_virtual_environment_firewall_rules" "inbound" {
  for_each = var.subnet == "public" ? toset([for i in range(0, var.node_count) : tostring(i)]) : toset([])
  depends_on = [
    proxmox_virtual_environment_vm.cluster_node,
  ]

  node_name = proxmox_virtual_environment_vm.cluster_node[each.key].node_name
  vm_id     = proxmox_virtual_environment_vm.cluster_node[each.key].vm_id

  rule {
    type    = "in"
    action  = "ACCEPT"
    comment = "Allow HTTP"
    dport   = "80"
    proto   = "tcp"
    log     = "info"
    iface   = "net1"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    comment = "Allow HTTPS"
    dport   = "443"
    proto   = "tcp"
    log     = "info"
    iface   = "net1"

  }

  rule {
    type    = "in"
    action  = "DROP"
    comment = "Allow SSH"
    dport   = "22"
    proto   = "tcp"
    log     = "info"
    iface   = "net1"
  }

  rule {
    type    = "in"
    action  = "ACCEPT"
    comment = "Allow ICMP"
    proto   = "icmp"
    log     = "info"
    iface   = "net1"
  }
}
