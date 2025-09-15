#!/usr/bin/env python3

import subprocess
import json
import os

def get_terraform_outputs():
    """Runs terraform output -json and returns the parsed JSON."""
    terraform_dir = os.path.join(os.path.dirname(__file__), '../../Iac/TERRAFORM') # Adjusted path
    try:
        result = subprocess.run(
            ['terraform', '-chdir=' + terraform_dir, 'output', '-json'],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running terraform output: {e.stderr}", file=os.stderr)
        exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing terraform output JSON: {e}", file=os.stderr)
        exit(1)

def generate_ansible_inventory():
    outputs = get_terraform_outputs()

    inventory = {
        "_meta": {
            "hostvars": {}
        },
        "all": {
            "children": []
        }
    }

    ssh_key_path = outputs.get("ssh_key_file_path", {}).get("value")
    bastion_public_ip = outputs.get("bastion_public_ip", {}).get("value")

    # Bastion Host
    if bastion_public_ip:
        inventory["bastion"] = {"hosts": ["bastion-host"]}
        inventory["_meta"]["hostvars"]["bastion-host"] = {
            "ansible_host": bastion_public_ip,
            "ansible_user": "ubuntu",
            "ansible_ssh_private_key_file": ssh_key_path,
            "ansible_ssh_common_args": f"-o StrictHostKeyChecking=no -o ForwardAgent=yes -o ProxyCommand=\"ssh -W %h:%p -q ubuntu@{bastion_public_ip} -i {ssh_key_path}\""
        }
        inventory["all"]["children"].append("bastion")

    # Manager Node
    manager_private_ip = outputs.get("manager_private_ip", {}).get("value")
    if manager_private_ip:
        inventory["manager"] = {"hosts": ["manager"]}
        inventory["_meta"]["hostvars"]["manager"] = {
            "ansible_host": manager_private_ip,
            "ansible_user": "ubuntu",
            "ansible_ssh_private_key_file": ssh_key_path,
            "ansible_ssh_common_args": f"-o StrictHostKeyChecking=no -o ForwardAgent=yes -o ProxyCommand=\"ssh -W %h:%p -q ubuntu@{bastion_public_ip} -i {ssh_key_path}\""
        }
        inventory["all"]["children"].append("manager")

    # Worker Nodes
    worker_private_ips = outputs.get("worker_private_ips", {}).get("value", [])
    if worker_private_ips:
        inventory["worker"] = {"hosts": []}
        for i, ip in enumerate(worker_private_ips):
            worker_name = f"worker{i+1}"
            inventory["worker"]["hosts"].append(worker_name)
            inventory["_meta"]["hostvars"][worker_name] = {
                "ansible_host": ip,
                "ansible_user": "ubuntu",
                "ansible_ssh_private_key_file": ssh_key_path,
                "ansible_ssh_common_args": f"-o StrictHostKeyChecking=no -o ForwardAgent=yes -o ProxyCommand=\"ssh -W %h:%p -q ubuntu@{bastion_public_ip} -i {ssh_key_path}\""
            }
        inventory["all"]["children"].append("worker")

    # Swarm Nodes (children of manager and worker)
    inventory["swarm_nodes"] = {"children": ["manager", "worker"]}
    inventory["all"]["children"].append("swarm_nodes")


    print(json.dumps(inventory, indent=4))

if __name__ == "__main__":
    generate_ansible_inventory()