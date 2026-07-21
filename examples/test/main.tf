module "captain" {
  source                = "../../"
  gluekube_docker_image = var.gluekube_docker_image
  gluekube_docker_tag   = var.gluekube_docker_tag

  provider_credentials = var.provider_credentials

  waggle_endpoint      = var.waggle_endpoint
  waggle_api_key       = var.waggle_api_key
  waggle_datacenter_id = var.waggle_datacenter_id

  cluster_metadata = {
    calico_network_calico_cidr = "172.16.0.0/16"
    network_service_cidr       = "192.168.0.0/16"
    cloud                      = "proxmox"
    cloud_vars = {
      calico_node_address_autodetection_v4 = "10.62.0.0/15"
    }
  }

  proxmox_config = {
    networks = {
      public = {
        name = "vmbr_public"
      }
      private = {
        name    = "vmbr_lan"
        vlan_id = 101
      }
      nat = {
        name    = "vmbr_nat"
        vlan_id = 201
      }
    }
  }

  bastion = {
    waggle_slot_name = "medium"
  }

  autoglue = {
    autoglue_cluster_name = var.autoglue_cluster_name

    credentials = {
      autoglue_key        = var.autoglue_key
      autoglue_org_secret = var.autoglue_org_secret
      base_url            = var.autoglue_base_url
    }

    route_53_config = {
      aws_access_key_id     = var.route53_aws_access_key_id
      aws_secret_access_key = var.route53_aws_secret_access_key
      aws_region            = var.route53_region
      domain_name           = var.domain_name
      zone_id               = var.route53_zone_id
      credential_id         = var.autoglue_credential_id
    }
  }

  node_pools = [
    {
      "name" : "master-node-pool",
      "subnet" : "private",
      "node_count" : 3,
      "role" : "master",
      "kubernetes_labels" : {},
      "kubernetes_taints" : [],
      "available_nodes" : [],
      "waggle_slot_name" : "large"
    },
    {
      "role" : "worker",
      "name" : "glueops-platform-node-pool",
      "subnet" : "private",
      "node_count" : 3,
      "kubernetes_labels" : {
        "glueops.dev/role" : "glueops-platform"
      },
      "kubernetes_taints" : [
        {
          key    = "glueops.dev/role"
          value  = "glueops-platform"
          effect = "NoSchedule"
        }
      ],
      "available_nodes" : [],
      "waggle_slot_name" : "large"
    },
    {
      "role" : "worker",
      "name" : "clusterwide",
      "subnet" : "private",
      "node_count" : 2,
      "kubernetes_labels" : {},
      "kubernetes_taints" : [],
      "available_nodes" : [],
      "waggle_slot_name" : "large"
    },

    {
      "role" : "worker",
      "name" : "public-loadbalancer-node-pool",
      "subnet" : "public",
      "node_count" : 2,
      "kubernetes_labels" : {
        "use-as-loadbalancer" : "public-traefik",
      },
      "kubernetes_taints" : [
        {
          key    = "dedicated"
          value  = "public-traefik"
          effect = "NoSchedule"
        }
      ],
      "available_nodes" : [],
      "waggle_slot_name" : "large"
    },
    {
      "role" : "worker",
      "name" : "platform-loadbalancer-node-pool",
      "subnet" : "public",
      "node_count" : 2,
      "kubernetes_labels" : {
        "use-as-loadbalancer" : "platform-traefik",
      },
      "kubernetes_taints" : [
        {
          key    = "dedicated"
          value  = "platform-traefik"
          effect = "NoSchedule"
        }
      ],
      "available_nodes" : [],
      "waggle_slot_name" : "large"
    },
    {
      "role" : "worker",
      "name" : "nginx-loadbalancer-node-pool",
      "subnet" : "public",
      "node_count" : 2,
      "kubernetes_labels" : {
        "use-as-loadbalancer" : "public",
      },
      "kubernetes_taints" : [
        {
          key    = "dedicated"
          value  = "public"
          effect = "NoSchedule"
        }
      ],
      "available_nodes" : [],
      "waggle_slot_name" : "large"
    },
  ]
}
