<!-- BEGIN_TF_DOCS -->
# opentofu-module-GlueKube-Proxmox

This opentofu module deploys a Kubernetes cluster on Proxmox VE using GlueKube.

```hcl
module "captain" {
  source                     = "git::https://github.com/GlueOps/opentofu-module-GlueKube-Proxmox.git"
  gluekube_docker_image      = "ghcr.io/glueops/gluekube"
  gluekube_docker_tag        = "v1.34.5-gluekube.8"
  calico_network_calico_cidr = "172.16.0.0/16"
  network_service_cidr       = "192.168.0.0/16"

  provider_credentials = {
    endpoint  = "https://proxmox.example.com:8006"
    api_token = "root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    insecure  = false
  }

  proxmox_config = {
    networks = {
      public = {
        name = "vmbr_public"
      }
      private = {
        name = "vmbr_lan"
      }
      nat = {
        name = "vmbr_nat"
      }
    }
    available_nodes = ["dev-hypervisor-01", "dev-hypervisor-02"]
  }

  bastion = {
    disk_size    = 20
    cores        = 4
    memory       = 8192
    proxmox_node = "dev-hypervisor-01"
  }

  autoglue = {
    autoglue_cluster_name = "my-cluster"

    credentials = {
      autoglue_key        = "your-autoglue-key"
      autoglue_org_secret = "your-autoglue-org-secret"
      base_url            = "https://autoglue.example.com"
    }
    route_53_config = {
      aws_access_key_id     = ""
      aws_secret_access_key = ""
      aws_region            = "us-east-1"
      domain_name           = "example.com"
      zone_id               = "Z3M3LMPEXAMPLE"
      credential_id         = "your-credential-id"
    }
  }

  node_pools = [
    {
      "name" : "master-node-pool",
      "subnet" : "private",
      "node_count" : 3,
      "disk_size" : 20,
      "cores" : 1,
      "memory" : 2048,
      "role" : "master",
      "kubernetes_labels" : {},
      "kubernetes_taints" : []
    },
    {
      "role" : "worker",
      "name" : "glueops-platform-node-pool-1",
      "subnet" : "private",
      "disk_size" : 20,
      "cores" : 1,
      "memory" : 2048,
      "node_count" : 5,
      "kubernetes_labels" : {
        "glueops.dev/role" : "glueops-platform"
        "use-as-loadbalancer" : "platform-traefik"
      },
      "kubernetes_taints" : [
        {
          key    = "glueops.dev/role"
          value  = "glueops-platform"
          effect = "NoSchedule"
        }
      ]
    }
  ]
}
```

<!-- END_TF_DOCS -->
