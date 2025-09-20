# Compute Module

Launches the EC2 instances that make up the Docker Swarm topology:

- Public bastion host with Elastic IP
- Private Swarm manager with fixed IP
- Private Swarm worker nodes (configurable map)

## Inputs
- `project_name`
- `instance_type`
- `ssh_key_name`
- `ssh_key_file_path`
- `security_group_id`
- `public_subnet_id`
- `private_subnet_a_id`, `private_subnet_b_id`
- `private_subnet_a_cidr`, `private_subnet_b_cidr`
- `manager_ip`
- `worker_nodes` (`map(object({ ip, subnet_cidr }))`)

## Outputs
- `bastion_public_ip`
- `manager_private_ip`
- `worker_private_ips`
- `ssh_key_file_path`

Worker entries must reference one of the supplied private subnet CIDR blocks; the module validates associations before creation.
