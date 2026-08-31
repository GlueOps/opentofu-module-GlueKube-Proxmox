# Compact view: which Proxmox node each VM lands on.
output "nodes_placement_targets" {
  value = [
    for p in data.waggle_pool_placements.nodes.placements : {
      node      = p.hypervisor_name
      placement = p.id
    }
  ]
}