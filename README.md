<!-- BEGIN_TF_DOCS -->
# opentofu-module-GlueKube-Proxmox

This opentofu module deploys a Kubernetes cluster on Proxmox VE using GlueKube.

```hcl
module "captain" {
  source                               = "git::https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox.git"
  gluekube_docker_image                = "ghcr.io/glueops/gluekube"
  gluekube_docker_tag                  = "v1.34.5-gluekube.11"
  calico_network_calico_cidr           = "172.16.0.0/16"
  calico_node_address_autodetection_v4 = "10.62.0.0/15"
  network_service_cidr                 = "192.168.0.0/16"
  provider_credentials                 = var.provider_credentials
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
    available_nodes = [""]

  }
  bastion = {
    disk_size    = 20
    cores        = 4
    memory       = 8192
    proxmox_node = ""
  }
  autoglue = {
    autoglue_cluster_name = var.autoglue_cluster_name

    credentials = {
      autoglue_key        = var.autoglue_key
      autoglue_org_secret = var.autoglue_org_secret
      base_url            = var.autoglue_base_url
    }
    route_53_config = {
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
      aws_region            = var.route53_region
      domain_name           = var.domain_name
      zone_id               = var.route53_zone_id
      credential_id         = var.autoglue_credentials_id
    }
  }
  node_pools = [
    {
      "name" : "master-node-pool-1",
      "subnet" : "private",

      "node_count" : 3,
      "disk_size" : 20,
      "cores" : 2,
      "memory" : 8192,
      "role" : "master",
      "kubernetes_labels" : {},
      "kubernetes_taints" : []
    },
    {
      "role" : "worker",
      "name" : "glueops-platform-node-pool-2",

      "subnet" : "private",
      "disk_size" : 20,
      "cores" : 2,
      "memory" : 8192,
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
      ]
    },

    {
      "role" : "worker",
      "name" : "glueops-platform-node-pool-3",

      "subnet" : "private",
      "disk_size" : 20,
      "cores" : 2,
      "memory" : 8192,
      "node_count" : 3,

      "kubernetes_labels" : {
        "glueops.dev/role" : "glueops-platform"
      },
      "kubernetes_taints" : []
    },

    {
      "role" : "worker",
      "name" : "platform-loadbalancer-node-pool",
      "subnet" : "public",
      "disk_size" : 20,
      "cores" : 2,
      "memory" : 8192,
      "node_count" : 2,

      "kubernetes_labels" : {
        "use-as-loadbalancer" : "platform-traefik",
        "glueops.dev/role" : "glueops-platform"

      },
      "kubernetes_taints" : [],
    },


    {
      "role" : "worker",
      "name" : "public-loadbalancer-node-pool",
      "subnet" : "public",
      "disk_size" : 20,
      "cores" : 2,
      "memory" : 8192,
      "node_count" : 2,

      "kubernetes_labels" : {
        "use-as-loadbalancer" : "public-traefik",
        "glueops.dev/role" : "glueops-platform"

      },
      "kubernetes_taints" : [],
    },


  ]
}

```

<!-- END_TF_DOCS -->
