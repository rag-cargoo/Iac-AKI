#!/usr/bin/env python3
"""Dynamic inventory for the AWS Ansible Docker Swarm project.

Reads Terraform-derived environment variables exported by setup_project_env.sh
and emits an inventory consumable by Ansible.
"""

import json
import os
import sys

REQUIRED_ENV_VARS = (
    "BASTION_PUBLIC_IP",
    "MANAGER_PRIVATE_IP",
    "SSH_KEY_PATH",
)

missing = [name for name in REQUIRED_ENV_VARS if not os.environ.get(name)]
if missing:
    sys.stderr.write(
        "Error: Missing required environment variables: {}\n".format(
            ", ".join(missing)
        )
    )
    sys.exit(1)

bastion_public_ip = os.environ["BASTION_PUBLIC_IP"].strip()
manager_private_ip = os.environ["MANAGER_PRIVATE_IP"].strip()
ssh_key_file = os.environ["SSH_KEY_PATH"].strip()
worker_private_ips_str = os.environ.get("WORKER_PRIVATE_IPS", "")
worker_private_ips = [ip for ip in worker_private_ips_str.split() if ip]

proxy_args = (
    f"-o StrictHostKeyChecking=no -o ForwardAgent=yes -o ProxyJump=ubuntu@{bastion_public_ip}"
)

inventory = {
    "_meta": {"hostvars": {}},
    "all": {"children": ["bastion", "swarm_nodes"]},
    "bastion": {"hosts": ["bastion-host"]},
    "swarm_manager": {"hosts": ["manager"]},
}

inventory["_meta"]["hostvars"]["bastion-host"] = {
    "ansible_host": bastion_public_ip,
    "ansible_user": "ubuntu",
    "ansible_ssh_private_key_file": ssh_key_file,
    "ansible_ssh_common_args": "-o StrictHostKeyChecking=no",
}

inventory["_meta"]["hostvars"]["manager"] = {
    "ansible_host": manager_private_ip,
    "ansible_user": "ubuntu",
    "ansible_ssh_private_key_file": ssh_key_file,
    "ansible_ssh_common_args": proxy_args,
}

if worker_private_ips:
    worker_group = []
    for index, ip in enumerate(worker_private_ips, start=1):
        host_name = f"worker{index}"
        worker_group.append(host_name)
        inventory["_meta"]["hostvars"][host_name] = {
            "ansible_host": ip,
            "ansible_user": "ubuntu",
            "ansible_ssh_private_key_file": ssh_key_file,
            "ansible_ssh_common_args": proxy_args,
        }
    inventory["swarm_worker"] = {"hosts": worker_group}
else:
    inventory["swarm_worker"] = {"hosts": []}

if "swarm_worker" not in inventory["all"]["children"]:
    inventory["all"]["children"].append("swarm_worker")

inventory["swarm_nodes"] = {
    "children": ["swarm_manager", "swarm_worker"]
}

print(json.dumps(inventory, indent=4))
