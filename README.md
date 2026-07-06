<!-- BEGIN_TF_DOCS -->
# opentofu-module-GlueKube-Proxmox

This opentofu module deploys a Kubernetes cluster on Proxmox VE using GlueKube.

```hcl

module "captain" {
  source                     = "git::https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox.git"
  gluekube_docker_image      = "ghcr.io/glueops/gluekube"
  gluekube_docker_tag        = "v0.0.15-rc9"
  cluster_name               = "my-cluster"
  proxmox_node               = "pve"
  datastore_id               = "local-lvm"
  cloud_init_datastore_id    = "local"
  calico_network_calico_cidr = "172.16.0.0/16"
  network_service_cidr       = "10.96.0.0/12"

  provider_credentials = {
    endpoint  = "https://proxmox.example.com:8006"
    api_token = "root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    insecure  = false
  }

  bastion = {
    cores       = 4
    memory      = 8192
    disk_size   = 40
    template_id = 9000
  }

  node_pools = [
    {
      "cores" : 4,
      "memory" : 8192,
      "disk_size" : 40,
      "template_id" : 9000,
      "role" : "master",
      "name" : "master-node-pool",
      "node_count" : 3,
      "kubernetes_labels" : {},
      "kubernetes_taints" : []
    },
    {
      "cores" : 4,
      "memory" : 8192,
      "disk_size" : 40,
      "template_id" : 9000,
      "role" : "worker",
      "name" : "glueops-platform-node-pool-1",
      "node_count" : 2,
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
      "cores" : 4,
      "memory" : 8192,
      "disk_size" : 40,
      "template_id" : 9000,
      "role" : "worker",
      "name" : "glueops-platform-node-pool-argocd-app-controller",
      "node_count" : 2,
      "kubernetes_labels" : {
        "glueops.dev/role" : "glueops-platform-argocd-app-controller"
      },
      "kubernetes_taints" : [
        {
          key    = "glueops.dev/role"
          value  = "glueops-platform-argocd-app-controller"
          effect = "NoSchedule"
        }
      ]
    },
    {
      "cores" : 4,
      "memory" : 8192,
      "disk_size" : 40,
      "template_id" : 9000,
      "role" : "worker",
      "name" : "clusterwide-node-pool-1",
      "node_count" : 2,
      "kubernetes_labels" : {},
      "kubernetes_taints" : []
    }
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
| <a name="module_cluster_metadata"></a> [cluster\_metadata](#module\_cluster\_metadata) | git::https://github.com/GlueOps/opentofu-module-autoglue-metadata.git | v0.0.1 |
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
| <a name="input_cluster_metadata"></a> [cluster\_metadata](#input\_cluster\_metadata) | Key-value pairs to store as cluster metadata | `map(string)` | `{}` | no |
| <a name="input_datastore_id"></a> [datastore\_id](#input\_datastore\_id) | The Proxmox datastore ID for VM disks | `string` | `"local"` | no |
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
