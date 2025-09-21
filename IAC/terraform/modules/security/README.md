# Security Module

Creates the shared security group for the Docker Swarm bastion, manager, and worker nodes. It allows:

- HTTP ingress from the internet (port 80) for published services.
- SSH ingress from a supplied operator CIDR for bastion access.
- Internal SSH/Swarm/monitoring traffic between nodes (self-referencing rules).
- Full egress for outbound connectivity.

## Inputs
- `project_name` (string)
- `vpc_id` (string)
- `operator_cidr` (string)

## Outputs
- `security_group_id`

Use the emitted security group ID when launching EC2 instances in the compute module.
