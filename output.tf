output "node_pools" {
  description = "Node pool information including IPs and roles"
  value = {
    for name, pool in module.node_pool : name => {
      role           = pool.role
      attached       = pool.attached
      ipv4_addresses = pool.node_ipv4_addresses
    }
  }
}

output "master_ipv4_addresses" {
  description = "The IPv4 addresses of master nodes grouped by node pool"
  value       = { for name, pool in module.node_pool : name => pool.node_ipv4_addresses if pool.role == "master" }
}

output "worker_ipv4_addresses" {
  description = "The IPv4 addresses of worker nodes grouped by node pool"
  value       = { for name, pool in module.node_pool : name => pool.node_ipv4_addresses if pool.role == "worker" }
}