output "role" {
  value = var.role
}

output "node_ipv4_addresses" {
  description = "The IPv4 addresses of nodes in this pool"
 value = [
    for vm in proxmox_virtual_environment_vm.cluster_node :
    one(flatten([
      for i, name in vm.network_interface_names :
      vm.ipv4_addresses[i] if name == "eth0"
    ]))
  ]
}

output "master_private_ips" {
  value = var.role == "master" ? [for s in autoglue_server.node : s.private_ip_address] : []
}

output "node_pool_id" {
  value = autoglue_node_pool.node_pool.id
}

output "attached" {
  value = var.attached
}
