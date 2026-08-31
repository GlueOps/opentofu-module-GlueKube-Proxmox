
data "waggle_slots" "available_slots" {
  name = var.bastion.waggle_slot_name
}

locals {
  cpu_cores = data.waggle_slots.available_slots.vcpu
  memory_mb = data.waggle_slots.available_slots.ram_gb * 1024
  disk_gb   = data.waggle_slots.available_slots.disk_gb

  # Deterministic per-cluster vm_id prefix derived from the captain domain (100-999).
  vm_id_prefix = 100 + parseint(substr(sha256(var.autoglue.route_53_config.domain_name), 0, 8), 16) % 900
}

module "waggle" {
  source               = "./modules/waggle"
  pool_name            = "${var.autoglue.autoglue_cluster_name}-bastion"
  slot_id              = data.waggle_slots.available_slots.id
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
  node_name    = module.waggle.nodes_placement_targets[0].node


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
  node_name = module.waggle.nodes_placement_targets[0].node

  description = "GlueKube bastion"

  vm_id   = local.vm_id_prefix * 500000 + (parseint(substr(sha256("${var.autoglue.autoglue_cluster_name}-bastion"), 0, 8), 16) % 10000) * 50
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

  lifecycle {
    ignore_changes = [vm_id]
  }
}


resource "waggle_placements" "bastion" {
  placement_id = module.waggle.nodes_placement_targets[0].placement
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
