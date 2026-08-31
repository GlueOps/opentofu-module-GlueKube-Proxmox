terraform {
  # OpenTofu / Terraform version. Provider constraints are inherited from the
  # root module (../../provider.tf): bpg/proxmox, GlueOps/autoglue and GlueOps/waggle.
  #
  # This example keeps no remote state: the run's state only has to survive one
  # job, and the nuke scripts are the teardown mechanism of record.
  required_version = ">= 1.0"

}
