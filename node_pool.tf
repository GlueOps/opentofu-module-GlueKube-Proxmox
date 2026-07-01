module "node_pool" {
  for_each               = { for np in var.node_pools : np.name => np }
  source                 = "./modules/gluekube"
  name                   = each.value.name
  role                   = each.value.role
  node_count             = each.value.node_count
  cores                  = each.value.cores
  memory                 = each.value.memory
  disk_size              = each.value.disk_size
  subnet                 = each.value.subnet
  kubernetes_labels      = each.value.kubernetes_labels
  kubernetes_taints      = each.value.kubernetes_taints
  kubernetes_annotations = each.value.kubernetes_annotations
  cluster_name           = var.autoglue.autoglue_cluster_name
  datastore_id           = var.datastore_id
  attached               = each.value.attached
  ballooning             = each.value.ballooning
  available_nodes        = each.value.available_nodes
  proxmox_config         = var.proxmox_config
}

resource "autoglue_cluster_node_pools" "autoglue_cluster_node_pools" {
  cluster_id = autoglue_cluster.cluster.id
  node_pool_ids = [
    for np in module.node_pool : np.node_pool_id if np.attached
  ]
}
