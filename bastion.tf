
data "waggle_slots" "available_slots" {
  count = var.bastion.waggle_slot_name != null ? 1 : 0
  name  = var.bastion.waggle_slot_name
}

locals {
  use_waggle = var.bastion.waggle_slot_name != null
  cpu_cores  = local.use_waggle ? data.waggle_slots.available_slots[0].vcpu : var.bastion.cores
  memory_mb  = local.use_waggle ? data.waggle_slots.available_slots[0].ram_gb * 1024 : var.bastion.memory
  disk_gb    = local.use_waggle ? data.waggle_slots.available_slots[0].disk_gb : var.bastion.disk_size
}

module "waggle" {
  count                = local.use_waggle ? 1 : 0
  source               = "./modules/waggle"
  pool_name            = "${var.autoglue.autoglue_cluster_name}-bastion"
  slot_id              = data.waggle_slots.available_slots[0].id
  desired_count        = 1
  waggle_datacenter_id = var.waggle_datacenter_id
}

resource "autoglue_ssh_key" "bastion" {
  name    = "${var.autoglue.autoglue_cluster_name}-bastion"
  comment = "GlueKube bastion SSH Key"
}

resource "proxmox_virtual_environment_file" "bastion_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.use_waggle ? module.waggle[0].nodes_placement_targets[0].node : var.bastion.proxmox_node


  source_raw {
    data = templatefile("${path.module}/cloudinit/cloud-init-bastion.yaml", {
      public_key = autoglue_ssh_key.bastion.public_key
      hostname   = "bastion"
    })
    file_name = "${var.autoglue.autoglue_cluster_name}-bastion-cloud-init.yaml"
  }
}


resource "proxmox_virtual_environment_vm" "bastion" {
  name      = "${var.autoglue.autoglue_cluster_name}-bastion"
  node_name = local.use_waggle ? module.waggle[0].nodes_placement_targets[0].node : var.bastion.proxmox_node

  description = "GlueKube bastion"

  vm_id   = local.use_waggle ? var.proxmox_config.networks.nat.vlan_id * 500000 + (parseint(substr(sha256("${var.autoglue.autoglue_cluster_name}-bastion"), 0, 8), 16) % 10000) * 50 : null
  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = local.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = local.memory_mb
    floating  = local.memory_mb / 2
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
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.bastion_cloud_init.id
  }

  network_device {
    bridge  = var.proxmox_config.networks.private.name
    model   = "virtio"
    vlan_id = var.proxmox_config.networks.private.vlan_id
  }

  network_device {
    bridge = var.proxmox_config.networks.public.name
    model  = "virtio"
  }

  agent {
    enabled = true
    timeout = "15m"
  }

  started = true

  tags = [var.autoglue.autoglue_cluster_name, "bastion"]
}


resource "waggle_placements" "bastion" {
  count        = local.use_waggle ? 1 : 0
  placement_id = module.waggle[0].nodes_placement_targets[0].placement
  vmid         = proxmox_virtual_environment_vm.bastion.vm_id

  lifecycle {
    ignore_changes = [placement_id]
  }
}


resource "autoglue_server" "bastion" {
  depends_on         = [proxmox_virtual_environment_vm.bastion]
  hostname           = "bastion"
  private_ip_address = proxmox_virtual_environment_vm.bastion.ipv4_addresses[1][0]
  public_ip_address  = proxmox_virtual_environment_vm.bastion.ipv4_addresses[2][0]
  role               = "bastion"
  ssh_key_id         = autoglue_ssh_key.bastion.id
  ssh_user           = "cluster"
}

resource "autoglue_cluster_bastion" "bastion" {
  cluster_id = autoglue_cluster.cluster.id
  server_id  = autoglue_server.bastion.id
}
