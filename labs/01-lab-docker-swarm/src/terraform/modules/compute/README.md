# Compute Module

Launches the EC2 instances that make up the Docker Swarm topology:

- Public bastion host with Elastic IP
- Swarm managers (list-driven)
- Swarm workers (list-driven)

## Inputs
- `project_name`
- `instance_type`
- `ssh_key_name`
- `ssh_key_file_path`
- `security_group_id`
- `public_subnet_id`
- `private_subnet_map` (map of subnet alias to subnet ID)
- `managers` (`list(object({ name, private_ip, subnet_name }))`)
- `workers` (`list(object({ name, private_ip, subnet_name }))`)

## Outputs
- `bastion_public_ip`
- `manager_private_ips`
- `worker_private_ips`
- `ssh_key_file_path`
