terraform {
  # OpenTofu / Terraform version. Provider constraints are inherited from the
  # root module (../../provider.tf): hashicorp/aws and GlueOps/autoglue.
  #
  # This example keeps no remote state: the run's state only has to survive one
  # job, and the nuke scripts are the teardown mechanism of record. The old
  # `>= 1.10` floor existed solely for native S3 state locking (use_lockfile),
  # which went with the backend — so this now matches the AWS example exactly.
  required_version = ">= 1.0"

}
