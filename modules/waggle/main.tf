resource "waggle_pools" "nodes" {
  name          = var.pool_name
  slot_id       = var.slot_id
  desired_count = var.desired_count
  datacenter_id = var.waggle_datacenter_id
}

# Read back the placements Waggle computed for the pool (one element per VM).
# pool_id is known-after-apply, so this reads during apply once the pool exists.
data "waggle_pool_placements" "nodes" {
  pool_id = waggle_pools.nodes.id
}


