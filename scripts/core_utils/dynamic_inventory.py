#!/usr/bin/env python3
import json
import os
import sys

def generate_ansible_inventory():
    bastion_public_ip = os.environ.get("BASTION_PUBLIC_IP")
    manager_private_ip = os.environ.get("MANAGER_PRIVATE_IP")
    worker_private_ips_str = os.environ.get("WORKER_PRIVATE_IPS")
    ssh_key_file = os.environ.get("SSH_KEY_PATH")

    if not bastion_public_ip or not manager_private_ip or not worker_private_ips_str or not ssh_key_file:
        print("Error: Required environment variables are not set.", file=sys.stderr)
        sys.exit(1)

    worker_private_ips = worker_private_ips_str.strip().split()
    inventory = {"_meta": {"hostvars": {}}, "all": {"children": []}}

    common_ssh_args = f"-o StrictHostKeyChecking=no -o ForwardAgent=yes -o ProxyJump=ubuntu@{bastion_public_ip} -i {ssh_key_file}"

    # Bastion
    inventory["bastion"] = {"hosts": ["bastion-host"]}
    inventory["_meta"]["hostvars"]["bastion-host"] = {
        "ansible_host": bastion_public_ip,
        "ansible_user": "ubuntu",
        "ansible_ssh_private_key_file": ssh_key_file
    }
    inventory["all"]["children"].append("bastion")

    # Manager
    inventory["swarm_manager"] = {"hosts": ["manager"]}
    inventory["_meta"]["hostvars"]["manager"] = {
        "ansible_host": manager_private_ip,
        "ansible_user": "ubuntu",
        "ansible_ssh_private_key_file": ssh_key_file,
        "ansible_ssh_common_args": common_ssh_args
    }
    inventory["all"]["children"].append("swarm_manager")

    # Workers
    if worker_private_ips:
        inventory["swarm_worker"] = {"hosts": []}
        for i, ip in enumerate(worker_private_ips):
            hostname = f"worker{i+1}"
            inventory["swarm_worker"]["hosts"].append(hostname)
            inventory["_meta"]["hostvars"][hostname] = {
                "ansible_host": ip,
                "ansible_user": "ubuntu",
                "ansible_ssh_private_key_file": ssh_key_file,
                "ansible_ssh_common_args": common_ssh_args
            }
        inventory["all"]["children"].append("swarm_worker")

    # Swarm nodes
    inventory["swarm_nodes"] = {"children": ["swarm_manager", "swarm_worker"]}
    inventory["all"]["children"].append("swarm_nodes")

    print(json.dumps(inventory, indent=4))

if __name__ == "__main__":
    generate_ansible_inventory()
