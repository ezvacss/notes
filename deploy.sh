#!/usr/bin/env bash
set -euo pipefail

cd infra
tofu init
tofu apply -auto-approve
IP=$(tofu output -raw notes_ip)
cd ..

echo "[*] VM created: ${IP}"

printf '[notes]\n%s ansible_user=admin ansible_ssh_private_key_file=~/.ssh/id_ed25519_awsCLI ansible_ssh_common_args="-o StrictHostKeyChecking=no"\n' \
  "${IP}" > ansible/inventory.ini

ansible-playbook -i ansible/inventory.ini ansible/notes.yml
echo "[*] Done: http://${IP}:8080/"
