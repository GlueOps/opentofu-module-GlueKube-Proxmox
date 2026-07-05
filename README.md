<!-- BEGIN_TF_DOCS -->
# opentofu-module-GlueKube-Proxmox

This opentofu module deploys a Kubernetes cluster on Proxmox VE using GlueKube.

## Waggle Integration

This module supports [Waggle](https://github.com/GlueOps/waggle) for automated VM placement and resource sizing. When Waggle is enabled, it replaces manual `cores`, `memory`, and `disk_size` settings in node pools with a `waggle_slot_name` that maps to a predefined resource slot managed by Waggle.


### Waggle Variables

| Variable | Description |
|----------|-------------|
| `waggle_endpoint` | The URL of the Waggle API server |
| `waggle_api_key` | API key for authenticating with Waggle |
| `waggle_datacenter_id` | The datacenter ID in Waggle that corresponds to your Proxmox environment |

### Node Pool Configuration with Waggle

When using Waggle, replace `cores`, `memory`, and `disk_size` in your node pool definitions with `waggle_slot_name`:

```hcl
node_pools = [
  {
    "name"              : "master-node-pool",
    "subnet"            : "private",
    "node_count"        : 3,
    "role"              : "master",
    "kubernetes_labels" : {},
    "kubernetes_taints" : [],
    "available_nodes"   : []
    "waggle_slot_name"  : "large",
  },
]
```


## Usage with Waggle

```hcl
module "captain" {
  source                = "git::https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox.git?ref=v0.2.0"
  gluekube_docker_image = "ghcr.io/glueops/gluekube"
  gluekube_docker_tag   = "" # Ask Hamza

  cluster_metadata = {
    calico_network_calico_cidr           = "" # e.g. 172.16.0.0/16 
    calico_node_address_autodetection_v4 = "" # e.g. 10.62.0.0/15
    network_service_cidr                 = "" # e.g. 192.168.0.0/16
  }
  provider_credentials = var.provider_credentials
  waggle_endpoint      = var.waggle_endpoint
  waggle_api_key       = var.waggle_api_key
  waggle_datacenter_id = var.waggle_datacenter_id
  proxmox_config = {
    networks = {
      public = {
        name = "vmbr_public"
      }
      private = {
        name    = "vmbr_lan"
        vlan_id = null # Ask Alanis
      }
      nat = {
        name    = "vmbr_nat"
        vlan_id = null # Ask Alanis
      }
    }
  }
  bastion = {
    waggle_slot_name = "large"
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
```

## Usage without Waggle

You can still use the module without Waggle by specifying `cores`, `memory`, and `disk_size` directly in each node pool and omitting the `waggle_slot_name` field:

```hcl
module "captain" {
  source                               = "git::https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox.git"
  gluekube_docker_image                = "ghcr.io/glueops/gluekube"
  gluekube_docker_tag                  = "v1.34.5-gluekube.25"
  calico_network_calico_cidr           = "172.16.0.0/16"
  calico_node_address_autodetection_v4 = "10.62.0.0/15"
  network_service_cidr                 = "192.168.0.0/16"
  provider_credentials                 = var.provider_credentials
  waggle_endpoint                      = var.waggle_endpoint
  waggle_api_key                       = var.waggle_api_key
  waggle_datacenter_id                 = var.waggle_datacenter_id
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
    disk_size    = 20
    cores        = 4
    memory       = 8192
    proxmox_node = "glueops-core-fs-hv01"
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
      "name"              : "master-node-pool",
      "subnet"            : "private",
      "node_count"        : 3,
      "disk_size"         : 20,
      "cores"             : 2,
      "memory"            : 8192,
      "role"              : "master",
      "kubernetes_labels" : {},
      "kubernetes_taints" : [],
      "available_nodes"   : ["glueops-core-fs-hv01", "glueops-core-fs-hv02", "glueops-core-fs-hv03"]
    },
  ]
}
```

<!-- END_TF_DOCS -->
