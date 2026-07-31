terraform {
  # OpenTofu / Terraform version. Provider constraints are inherited from the
  # root module (../../provider.tf): hashicorp/aws and GlueOps/autoglue.
  # >= 1.10 is required for native S3 state locking (use_lockfile) below.
  required_version = ">= 1.10"

}
