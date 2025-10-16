# Production Environment

Entry point for provisioning the production Docker Swarm infrastructure. This layer consumes the upstream `terraform-aws-modules/vpc/aws` module alongside local security/compute modules under `../../modules`.

## Usage
```bash
# From infra/terraform/envs/production
terraform init
terraform plan
terraform apply
```

## Files
- `main.tf` – module composition and provider definition
- `variables.tf` – input interface for the environment
- `outputs.tf` – re-exposed outputs for downstream tooling
- `terraform.tfvars` – environment-specific variable values (do not commit secrets)
- `backend.tf` – backend configuration (defaults to local state; replace with S3/DynamoDB in production)

## Notes
- Copy `terraform.tfvars` values for staging/dev into separate environment directories as needed.
- When migrating existing state, move state files into `../../state/<environment>` or configure a remote backend before running `terraform init`.
