
data "waggle_slots" "available_slots" {
  count = local.bastion_count

  name = var.bastion.waggle_slot_name
}

locals {
  bastion_count = var.bastion.create ? 1 : 0

  bastion_slot = one(data.waggle_slots.available_slots)

  cpu_cores = try(local.bastion_slot.vcpu, 0)
  memory_mb = try(local.bastion_slot.ram_gb * 1024, 0)
  disk_gb   = try(local.bastion_slot.disk_gb, 0)

  # Deterministic per-cluster vm_id prefix derived from the captain domain (100-999).
  vm_id_prefix = 100 + parseint(substr(sha256(var.autoglue.route_53_config.domain_name), 0, 8), 16) % 900
}

module "waggle" {
  count = local.bastion_count

  source               = "./modules/waggle"
  pool_name            = "${var.autoglue.autoglue_cluster_name}-bastion"
  slot_id              = data.waggle_slots.available_slots[0].id
  desired_count        = 1
  waggle_datacenter_id = var.waggle_datacenter_id
}

resource "autoglue_ssh_key" "bastion" {
  count = local.bastion_count

  name    = "${var.autoglue.autoglue_cluster_name}-bastion"
  comment = "GlueKube bastion SSH Key"
}

resource "proxmox_virtual_environment_vm" "bastion" {
  count = local.bastion_count

  name      = "${var.autoglue.autoglue_cluster_name}-bastion"
  node_name = module.waggle[0].nodes_placement_targets[0].node

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

  # Empty drive for proxmox_cloudinit_bootstrap to attach the seed ISO to (ide0 is its default interface).
  cdrom {
    interface = "ide0"
    file_id   = "none"
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

  # proxmox_cloudinit_bootstrap starts the VM once the seed ISO is attached.
  started = false

  tags = [var.autoglue.autoglue_cluster_name, "bastion"]

  lifecycle {
    ignore_changes = [node_name, initialization, vm_id, started]
  }
}

resource "proxmox_cloudinit_bootstrap" "bastion" {
  count = local.bastion_count

  vm_id        = proxmox_virtual_environment_vm.bastion[0].vm_id
  datastore_id = "local"
  file_name    = "${var.autoglue.autoglue_cluster_name}-bastion-cloud-init.iso"

  user_data = templatefile("${path.module}/cloudinit/cloud-init-bastion.yaml", {
    public_key = autoglue_ssh_key.bastion[0].public_key
    hostname   = "bastion"
  })

  network_config = yamlencode({
    version = 1
    # Names the NICs eth0/eth1 (the IP lookups rely on it) and runs DHCP on each; without `initialization`, Proxmox generates no network config.
    config = [for n, nic in proxmox_virtual_environment_vm.bastion[0].network_device : {
      type        = "physical"
      name        = "eth${n}"
      mac_address = lower(nic.mac_address)
      subnets     = [{ type = "dhcp" }]
    }]
  })

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.bastion[0].id]
  }
}


resource "waggle_placements" "bastion" {
  count = local.bastion_count

  placement_id = module.waggle[0].nodes_placement_targets[0].placement
  vmid         = proxmox_virtual_environment_vm.bastion[0].vm_id

  lifecycle {
    ignore_changes = [placement_id]
  }
}


resource "autoglue_server" "bastion" {
  count = local.bastion_count

  depends_on         = [proxmox_virtual_environment_vm.bastion]
  hostname           = "bastion"
  private_ip_address = proxmox_cloudinit_bootstrap.bastion[0].ipv4_addresses["eth0"][0]
  public_ip_address  = proxmox_cloudinit_bootstrap.bastion[0].ipv4_addresses["eth1"][0]
  role               = "bastion"
  ssh_key_id         = autoglue_ssh_key.bastion[0].id
  ssh_user           = "cluster"

  lifecycle {
    precondition {
      # initialization is in ignore_changes, so this shows how the VM was created: a cloud-init drive means snippet mode.
      condition     = length(proxmox_virtual_environment_vm.bastion[0].initialization) == 0
      error_message = "The bastion still uses a cloud-init snippet, which 0.6.0 removed. Go back to 0.5.x and move it to cloud_init = \"iso\" first (see its upgrade guide)."
    }
  }
}

resource "autoglue_cluster_bastion" "bastion" {
  count = local.bastion_count

  cluster_id = autoglue_cluster.cluster.id
  server_id  = autoglue_server.bastion[0].id
}
