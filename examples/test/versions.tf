terraform {
  # OpenTofu / Terraform version. Provider constraints are inherited from the
  # root module (../../provider.tf): hashicorp/aws and GlueOps/autoglue.
  # >= 1.10 is required for native S3 state locking (use_lockfile) below.
  required_version = ">= 1.10"

  # Partial backend config: bucket/key/region/creds are supplied at `tofu init`
  # time via -backend-config flags in the workflow, so this example carries no
  # environment-specific values or credentials.
  backend "s3" {
    use_lockfile = true # native S3 locking (OpenTofu >= 1.10) — no DynamoDB table
    encrypt      = true
  }
}
