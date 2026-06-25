data "waggle_slots" "available_slots" {
  count = var.waggle_slot_name != null ? 1 : 0
  name  = var.waggle_slot_name
}

locals {
  use_waggle = var.waggle_slot_name != null
  cpu_cores  = local.use_waggle ? data.waggle_slots.available_slots[0].vcpu : var.cores
  memory_mb  = local.use_waggle ? data.waggle_slots.available_slots[0].ram_gb * 1024 : var.memory
  disk_gb    = local.use_waggle ? data.waggle_slots.available_slots[0].disk_gb : var.disk_size
}

resource "autoglue_ssh_key" "ssh_key" {
  name    = "${var.cluster_name}-${var.name}"
  comment = "GlueKube ${var.role} SSH Key"
}

module "waggle" {
  count                = local.use_waggle ? 1 : 0
  source               = "../waggle"
  pool_name            = "${var.cluster_name}-${var.name}-${var.role}"
  slot_id              = data.waggle_slots.available_slots[0].id
  desired_count        = var.node_count
  waggle_datacenter_id = var.waggle_datacenter_id
}


resource "random_shuffle" "available_nodes" {
  input        = var.available_nodes
  result_count = length(var.available_nodes)
}

resource "proxmox_virtual_environment_file" "node_cloud_init" {
  for_each     = toset([for i in range(0, var.node_count) : tostring(i)])
  content_type = "snippets"
  datastore_id = "local"
  node_name    = length(var.available_nodes) > 0 ? random_shuffle.available_nodes.result[tonumber(each.key) % length(random_shuffle.available_nodes.result)] : module.waggle[0].nodes_placement_targets[each.key].node

  source_raw {
    data = templatefile("${path.module}/cloudinit/cloud-init.yaml", {
      public_key = autoglue_ssh_key.ssh_key.public_key
      hostname   = "${var.role}-${var.name}-${each.key}"
    })
    file_name = "${var.cluster_name}-${var.role}-${var.name}-${each.key}-cloud-init.yaml"
  }
}



resource "proxmox_virtual_environment_vm" "cluster_node" {
  for_each  = toset([for i in range(0, var.node_count) : tostring(i)])
  name      = "${var.role}-${var.name}-${each.key}"
  node_name = length(var.available_nodes) > 0 ? random_shuffle.available_nodes.result[tonumber(each.key) % length(random_shuffle.available_nodes.result)] : module.waggle[0].nodes_placement_targets[each.key].node

  description = "GlueKube ${var.role} node - ${var.name}-${each.key}"

  # vm_id = local.use_waggle ? var.proxmox_config.networks.private.vlan_id * 500000 + each.key : null

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = local.cpu_cores
    type  = "x86-64-v2-AES"
    numa  = true
  }

  memory {
    dedicated = local.memory_mb
    floating  = var.ballooning ? local.memory_mb / 2 : local.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
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

resource "waggle_placements" "workers" {
  for_each     = toset([for i in range(0, var.node_count) : tostring(i)])
  placement_id = module.waggle[0].nodes_placement_targets[each.key].placement
  vmid         = proxmox_virtual_environment_vm.cluster_node[each.key].vm_id
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
