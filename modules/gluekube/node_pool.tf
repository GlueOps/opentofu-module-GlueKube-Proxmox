resource "autoglue_server" "node" {
  for_each           = toset([for i in range(0, var.node_count) : tostring(i)])
  hostname           = "${var.role}-${var.name}-${each.key}"
private_ip_address = proxmox_virtual_environment_vm.cluster_node[each.key].ipv4_addresses[
    index(proxmox_virtual_environment_vm.cluster_node[each.key].network_interface_names, "eth0")
  ][0]
  public_ip_address = var.subnet == "public" ? proxmox_virtual_environment_vm.cluster_node[each.key].ipv4_addresses[
    index(proxmox_virtual_environment_vm.cluster_node[each.key].network_interface_names, "eth1")
    ][0] : proxmox_virtual_environment_vm.cluster_node[each.key].ipv4_addresses[
    index(proxmox_virtual_environment_vm.cluster_node[each.key].network_interface_names, "eth0")
  ][0]
  role               = var.role
  ssh_key_id         = autoglue_ssh_key.ssh_key.id
  ssh_user           = "cluster"
}


resource "autoglue_node_pool" "node_pool" {
  name = "${var.role}-${var.name}"
  role = var.role
}

resource "autoglue_node_pool_servers" "node_pool_servers" {
  node_pool_id = autoglue_node_pool.node_pool.id
  server_ids   = [for s in autoglue_server.node : s.id]
}


resource "autoglue_taint" "node_taints" {
  for_each = { for idx, taint in var.kubernetes_taints : idx => taint }

  key    = each.value.key
  value  = each.value.value
  effect = each.value.effect
}


resource "autoglue_label" "node_labels" {
  for_each = var.kubernetes_labels
  key      = each.key
  value    = each.value
}

resource "autoglue_annotation" "node_annotations" {
  for_each = var.kubernetes_annotations
  key      = each.key
  value    = each.value
}

resource "autoglue_node_pool_labels" "node_pool_labels" {
  count        = length(var.kubernetes_labels) > 0 ? 1 : 0
  node_pool_id = autoglue_node_pool.node_pool.id
  label_ids    = [for label in autoglue_label.node_labels : label.id]
}

resource "autoglue_node_pool_taints" "node_pool_taints" {
  count        = length(var.kubernetes_taints) > 0 ? 1 : 0
  node_pool_id = autoglue_node_pool.node_pool.id
  taint_ids    = [for taint in autoglue_taint.node_taints : taint.id]
}

resource "autoglue_node_pool_annotations" "node_pool_annotations" {
  count          = length(var.kubernetes_annotations) > 0 ? 1 : 0
  node_pool_id   = autoglue_node_pool.node_pool.id
  annotation_ids = [for annotation in autoglue_annotation.node_annotations : annotation.id]
}
