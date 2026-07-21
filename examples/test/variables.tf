variable "provider_credentials" {
  type = object({
    name        = string
    endpoint    = string
    api_token   = optional(string)
    username    = optional(string)
    password    = optional(string)
    insecure    = optional(bool, false)
    private_key = optional(string)
  })
}

variable "gluekube_docker_image" {
  type    = string
  default = "ghcr.io/glueops/gluekube"
}

variable "gluekube_docker_tag" {
  type    = string
  default = "v0.0.15-rc9"
}


################################
# AutoGlue integration
################################
variable "autoglue_cluster_name" {
  type        = string
  description = "Cluster name to register in AutoGlue."
}

variable "autoglue_key" {
  type        = string
  description = "AutoGlue org key."
  sensitive   = true
}

variable "autoglue_org_secret" {
  type        = string
  description = "AutoGlue org secret."
  sensitive   = true
}

variable "autoglue_base_url" {
  type        = string
  description = "Base URL of the AutoGlue API."
}

################################
# Route53 config (AutoGlue captain domain)
################################
variable "route53_aws_access_key_id" {
  type        = string
  description = "AWS access key id used by AutoGlue for Route53 management."
  sensitive   = true
}

variable "route53_aws_secret_access_key" {
  type        = string
  description = "AWS secret access key used by AutoGlue for Route53 management."
  sensitive   = true
}

variable "route53_region" {
  type        = string
  description = "AWS region for the Route53 provider."
  default     = "us-west-2"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the captain domain."
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone id for the domain."
}

variable "autoglue_credential_id" {
  type        = string
  description = "AutoGlue credential id referencing the Route53 credentials."
}



variable "waggle_endpoint" {
  type    = string
  default = null
}

variable "waggle_api_key" {
  type    = string
  default = null
}

variable "waggle_datacenter_id" {
  type    = string
  default = null
}
