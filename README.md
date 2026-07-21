<!-- BEGIN_TF_DOCS -->
# opentofu-module-GlueKube-Proxmox

This opentofu module deploys a Kubernetes cluster on Proxmox VE using GlueKube.

```hcl

module "captain" {
  source                = "git::https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox?ref=v0.3.0" # x-release-please-version
  gluekube_docker_image = "ghcr.io/glueops/gluekube"
  gluekube_docker_tag   = "v1.34.5-gluekube.27"

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
      "available_nodes" : ["pve1","pve2","pve3"], # if available_nodes isn't empty, it get considered instead of waggle  
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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_autoglue"></a> [autoglue](#requirement\_autoglue) | 0.10.12 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | 0.110.0 |
| <a name="requirement_waggle"></a> [waggle](#requirement\_waggle) | 0.1.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_autoglue"></a> [autoglue](#provider\_autoglue) | 0.10.12 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.110.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_waggle"></a> [waggle](#provider\_waggle) | 0.1.20 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_metadata"></a> [cluster\_metadata](#module\_cluster\_metadata) | git::https://github.com/GlueOps/opentofu-module-autoglue-metadata.git | v0.0.2 |
| <a name="module_node_pool"></a> [node\_pool](#module\_node\_pool) | ./modules/gluekube | n/a |
| <a name="module_waggle"></a> [waggle](#module\_waggle) | ./modules/waggle | n/a |

## Resources

| Name | Type |
|------|------|
| autoglue_cluster.cluster | resource |
| autoglue_cluster_bastion.bastion | resource |
| autoglue_cluster_captain_domain.domain | resource |
| autoglue_cluster_control_plane_record_set.ctrl_record | resource |
| autoglue_cluster_node_pools.autoglue_cluster_node_pools | resource |
| autoglue_domain.captain | resource |
| autoglue_record_set.cluster_record | resource |
| autoglue_server.bastion | resource |
| autoglue_ssh_key.bastion | resource |
| [proxmox_virtual_environment_file.bastion_cloud_init](https://registry.terraform.io/providers/bpg/proxmox/0.110.0/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.bastion](https://registry.terraform.io/providers/bpg/proxmox/0.110.0/docs/resources/virtual_environment_vm) | resource |
| [random_integer.vm_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| waggle_placements.bastion | resource |
| waggle_slots.available_slots | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoglue"></a> [autoglue](#input\_autoglue) | Configuration for the AutoGlue platform integration, including cluster naming, credentials, and Route53 DNS settings. | <pre>object({<br/>    autoglue_cluster_name = string<br/><br/>    credentials = object({<br/>      autoglue_key        = string<br/>      autoglue_org_secret = string<br/>      base_url            = string<br/>    })<br/><br/>    route_53_config = object({<br/>      aws_access_key_id     = string<br/>      aws_secret_access_key = string<br/>      aws_region            = string<br/>      domain_name           = string<br/>      zone_id               = string<br/>      credential_id         = string<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_bastion"></a> [bastion](#input\_bastion) | Bastion configuration. | <pre>object({<br/>    waggle_slot_name = string<br/>  })</pre> | n/a | yes |
| <a name="input_cluster_metadata"></a> [cluster\_metadata](#input\_cluster\_metadata) | Structured cluster metadata passed through to the autoglue-metadata module. All fields are required unless noted:<br/>  - calico\_network\_calico\_cidr: CIDR block for the Calico pod network (e.g. "10.244.0.0/16").<br/>  - network\_service\_cidr:       CIDR block for Kubernetes services (e.g. "10.96.0.0/12").<br/>  - cloud:                      Target cloud provider. One of: "aws", "proxmox", "hetzner".<br/>  - cloud\_vars:                 Optional map of cloud-specific overrides. When cloud is "proxmox",<br/>                                "calico\_node\_address\_autodetection\_v4" is required. | <pre>object({<br/>    calico_network_calico_cidr = string<br/>    network_service_cidr       = string<br/>    cloud                      = string<br/>    cloud_vars                 = optional(map(string), {}) # Holds the cloud-specific overrides<br/>  })</pre> | n/a | yes |
| <a name="input_gluekube_docker_image"></a> [gluekube\_docker\_image](#input\_gluekube\_docker\_image) | n/a | `string` | `"ghcr.io/glueops/gluekube"` | no |
| <a name="input_gluekube_docker_tag"></a> [gluekube\_docker\_tag](#input\_gluekube\_docker\_tag) | n/a | `string` | `"v0.0.15-rc9"` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | n/a | <pre>list(object({<br/>    name                   = string<br/>    node_count             = number<br/>    role                   = string<br/>    subnet                 = optional(string, "public")<br/>    cores                  = optional(number)<br/>    memory                 = optional(number)<br/>    disk_size              = optional(number)<br/>    kubernetes_labels      = optional(map(string), {})<br/>    kubernetes_annotations = optional(map(string), {})<br/>    kubernetes_taints = list(object({<br/>      key    = string<br/>      value  = string<br/>      effect = string<br/>    }))<br/>    available_nodes  = list(string)<br/>    attached         = optional(bool, true)<br/>    ballooning       = optional(bool, true)<br/>    waggle_slot_name = optional(string)<br/><br/>  }))</pre> | n/a | yes |
| <a name="input_provider_credentials"></a> [provider\_credentials](#input\_provider\_credentials) | n/a | <pre>object({<br/>    name        = string<br/>    endpoint    = string<br/>    api_token   = optional(string)<br/>    username    = optional(string)<br/>    password    = optional(string)<br/>    insecure    = optional(bool, false)<br/>    private_key = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_proxmox_config"></a> [proxmox\_config](#input\_proxmox\_config) | Proxmox infrastructure configuration including network bridges. | <pre>object({<br/>    networks = object({<br/>      public = object({<br/>        name = string<br/>      })<br/>      private = object({<br/>        name    = string<br/>        vlan_id = optional(number)<br/>      })<br/>      nat = object({<br/>        name    = string<br/>        vlan_id = optional(number)<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_waggle_api_key"></a> [waggle\_api\_key](#input\_waggle\_api\_key) | n/a | `string` | `null` | no |
| <a name="input_waggle_datacenter_id"></a> [waggle\_datacenter\_id](#input\_waggle\_datacenter\_id) | n/a | `string` | `null` | no |
| <a name="input_waggle_endpoint"></a> [waggle\_endpoint](#input\_waggle\_endpoint) | n/a | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
