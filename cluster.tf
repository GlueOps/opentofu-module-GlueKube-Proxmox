resource "autoglue_cluster" "cluster" {
  cluster_provider = var.provider_credentials.name
  docker_image     = var.gluekube_docker_image
  docker_tag       = var.gluekube_docker_tag
  name             = var.autoglue.autoglue_cluster_name
  region           = var.autoglue.route_53_config.aws_region
}


resource "autoglue_domain" "captain" {
  domain_name   = var.autoglue.route_53_config.domain_name
  credential_id = var.autoglue.route_53_config.credential_id
  zone_id       = var.autoglue.route_53_config.zone_id
}

resource "autoglue_record_set" "cluster_record" {
  domain_id = autoglue_domain.captain.id
  name      = "ctrp"
  type      = "A"
  ttl       = 60
  values    = flatten([for name, pool in module.node_pool : pool.role == "master" ? pool.master_private_ips : []])
}

resource "autoglue_cluster_captain_domain" "domain" {
  cluster_id = autoglue_cluster.cluster.id
  domain_id  = autoglue_domain.captain.id
}

resource "autoglue_cluster_control_plane_record_set" "ctrl_record" {
  cluster_id    = autoglue_cluster.cluster.id
  record_set_id = autoglue_record_set.cluster_record.id
}

resource "autoglue_cluster_metadata" "service_cidr" {
  cluster_id = autoglue_cluster.cluster.id
  key        = "network_service_cidr"
  value      = var.network_service_cidr
}

resource "autoglue_cluster_metadata" "calico_cidr" {
  cluster_id = autoglue_cluster.cluster.id
  key        = "calico_network_calico_cidr"
  value      = var.calico_network_calico_cidr
}

resource "autoglue_cluster_metadata" "calico_node_address_autodetection_v4" {
  count = var.calico_node_address_autodetection_v4 != null ? 1 : 0
  cluster_id = autoglue_cluster.cluster.id
  key        = "calico_node_address_autodetection_v4"
  value      = var.calico_node_address_autodetection_v4
}