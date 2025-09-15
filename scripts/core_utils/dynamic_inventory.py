#!/usr/bin/env python3

import json
import os
import sys

def generate_ansible_inventory():
    # Fetch IPs and Key Path from Environment Variables
    bastion_public_ip = os.environ.get("BASTION_PUBLIC_IP")
    manager_private_ip = os.environ.get("MANAGER_PRIVATE_IP")
    worker_private_ips_str = os.environ.get("WORKER_PRIVATE_IPS")
    ssh_key_file = os.environ.get("SSH_KEY_PATH")

    if not bastion_public_ip or not manager_private_ip or not worker_private_ips_str or not ssh_key_file:
        print("Error: Required environment variables (BASTION_PUBLIC_IP, MANAGER_PRIVATE_IP, WORKER_PRIVATE_IPS, SSH_KEY_PATH) are not set.", file=sys.stderr)
        print("Please source scripts/core_utils/setup_project_env.sh first.", file=sys.stderr)
        sys.exit(1)

    # Convert WORKER_PRIVATE_IPS_STR from shell array string to Python list
    # Example: '10.0.102.10' '10.0.101.11' -> ['10.0.102.10', '10.0.101.11']
    worker_private_ips = worker_private_ips_str.strip().split()

    inventory = {
        "_meta": {
            "hostvars": {}
        },
        "all": {
            "children": []
        }
    }

    # Define common SSH args for hosts behind bastion
    common_ssh_args = f"-o StrictHostKeyChecking=no -o ForwardAgent=yes -o ProxyCommand=\"ssh -W %h:%p -q ubuntu@{bastion_public_ip} -i {ssh_key_file}\""

    # Bastion Host
    inventory["bastion"] = {"hosts": ["bastion-host"]}
    inventory["_meta"]["hostvars"]["bastion-host"] = {
        "ansible_host": bastion_public_ip,
        "ansible_user": "ubuntu",
        "ansible_ssh_private_key_file": ssh_key_file
    }
    inventory["all"]["children"].append("bastion")

    # Manager Node
    inventory["swarm_manager"] = {"hosts": ["manager"]}
    inventory["_meta"]["hostvars"]["manager"] = {
        "ansible_host": manager_private_ip,
        "ansible_user": "ubuntu",
        "ansible_ssh_private_key_file": ssh_key_file,
        "ansible_ssh_common_args": common_ssh_args # Apply common SSH args here
    }
    inventory["all"]["children"].append("swarm_manager")

    # Worker Nodes
    if worker_private_ips:
        inventory["swarm_worker"] = {"hosts": []}
        for i, ip in enumerate(worker_private_ips):
            hostname = f"worker{i+1}"
            inventory["swarm_worker"]["hosts"].append(hostname)
            inventory["_meta"]["hostvars"][hostname] = {
                "ansible_host": ip,
                "ansible_user": "ubuntu",
                "ansible_ssh_private_key_file": ssh_key_file,
                "ansible_ssh_common_args": common_ssh_args # Apply common SSH args here
            }
        inventory["all"]["children"].append("swarm_worker")

    # Swarm Nodes Group
    inventory["swarm_nodes"] = {"children": ["swarm_manager", "swarm_worker"]}
    inventory["all"]["children"].append("swarm_nodes")

    # No need for "all" vars for common_ssh_args anymore.

    print(json.dumps(inventory, indent=4))

if __name__ == "__main__":
    generate_ansible_inventory()
