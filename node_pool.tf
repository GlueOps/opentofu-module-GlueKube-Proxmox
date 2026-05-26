locals {
  unique_available_nodes = toset(flatten([for np in var.node_pools : np.available_nodes]))
}

resource "autoglue_ssh_key" "node" {
  name    = "${var.autoglue.autoglue_cluster_name}-nodes"
  comment = "GlueKube node SSH Key"
}

resource "proxmox_virtual_environment_file" "node_cloud_init" {
  for_each     = local.unique_available_nodes
  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value

  source_raw {
    data = templatefile("${path.module}/modules/gluekube/cloudinit/cloud-init.yaml", {
      public_key = autoglue_ssh_key.node.public_key
    })
    file_name = "${var.autoglue.autoglue_cluster_name}-${substr(md5(each.value), 0, 8)}-node-cloud-init.yaml"
  }
}

locals {
  cloud_init_file_ids_by_node = {
    for node_name, cloud_init in proxmox_virtual_environment_file.node_cloud_init : node_name => cloud_init.id
  }
}

module "node_pool" {
  for_each                    = { for np in var.node_pools : np.name => np }
  source                      = "./modules/gluekube"
  name                        = each.value.name
  role                        = each.value.role
  node_count                  = each.value.node_count
  cores                       = each.value.cores
  memory                      = each.value.memory
  disk_size                   = each.value.disk_size
  subnet                      = each.value.subnet
  kubernetes_labels           = each.value.kubernetes_labels
  kubernetes_taints           = each.value.kubernetes_taints
  kubernetes_annotations      = each.value.kubernetes_annotations
  cluster_name                = var.autoglue.autoglue_cluster_name
  datastore_id                = var.datastore_id
  attached                    = each.value.attached
  ballooning                  = each.value.ballooning
  available_nodes             = each.value.available_nodes
  shared_ssh_key_id           = autoglue_ssh_key.node.id
  cloud_init_file_ids_by_node = local.cloud_init_file_ids_by_node
  proxmox_config              = var.proxmox_config
}

resource "autoglue_cluster_node_pools" "autoglue_cluster_node_pools" {
  cluster_id = autoglue_cluster.cluster.id
  node_pool_ids = [
    for np in module.node_pool : np.node_pool_id if np.attached
  ]
}
