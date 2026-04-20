#!/bin/bash
set -euo pipefail

# KijaniKiosk Full IaC Pipeline
# Phase 1: Terraform provisions infrastructure
# Phase 2: Inventory is written from Terraform outputs
# Phase 3: Ansible configures all three servers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"
SSH_KEY="$HOME/.ssh/kijanikiosk-aws.pem"
ANSIBLE_USER="ubuntu"

echo "============================================"
echo "  KijaniKiosk IaC Pipeline"
echo "  $(date)"
echo "============================================"

# --- PHASE 1: TERRAFORM ---
echo ""
echo ">>> Phase 1: Terraform - Provisioning infrastructure"
echo "--------------------------------------------"

cd "$TERRAFORM_DIR"

terraform init -input=false

echo ""
echo ">>> Running terraform plan..."
terraform plan -out=pipeline.tfplan

echo ""
echo ">>> Running terraform apply..."
terraform apply pipeline.tfplan

echo ""
echo ">>> Extracting server IPs from Terraform outputs..."
API_IP=$(terraform output -raw api_server_ip)
PAYMENTS_IP=$(terraform output -raw payments_server_ip)
LOGS_IP=$(terraform output -raw logs_server_ip)

echo "  API:      $API_IP"
echo "  Payments: $PAYMENTS_IP"
echo "  Logs:     $LOGS_IP"

# --- PHASE 2: WRITE INVENTORY ---
echo ""
echo ">>> Phase 2: Writing Ansible inventory from Terraform outputs"
echo "--------------------------------------------"

cat > "$ANSIBLE_DIR/inventory.ini" << INVENTORY
[kijanikiosk_api]
api-staging ansible_host=$API_IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$SSH_KEY

[kijanikiosk_payments]
payments-staging ansible_host=$PAYMENTS_IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$SSH_KEY

[kijanikiosk_logs]
logs-staging ansible_host=$LOGS_IP ansible_user=$ANSIBLE_USER ansible_ssh_private_key_file=$SSH_KEY

[kijanikiosk:children]
kijanikiosk_api
kijanikiosk_payments
kijanikiosk_logs

[kijanikiosk:vars]
ansible_python_interpreter=/usr/bin/python3
INVENTORY

echo "  Inventory written to $ANSIBLE_DIR/inventory.ini"

# --- PHASE 3: WAIT FOR SSH ---
echo ""
echo ">>> Phase 3: Waiting for SSH to be available on all servers..."
echo "--------------------------------------------"

for IP in "$API_IP" "$PAYMENTS_IP" "$LOGS_IP"; do
  echo -n "  Waiting for $IP..."
  for i in $(seq 1 30); do
    if ssh -i "$SSH_KEY" \
       -o StrictHostKeyChecking=no \
       -o ConnectTimeout=5 \
       -o BatchMode=yes \
       "$ANSIBLE_USER@$IP" "echo ok" &>/dev/null; then
      echo " ready"
      break
    fi
    echo -n "."
    sleep 5
    if [ "$i" -eq 30 ]; then
      echo " TIMEOUT"
      echo "ERROR: Could not connect to $IP after 150 seconds"
      exit 1
    fi
  done
done

# --- PHASE 4: ANSIBLE ---
echo ""
echo ">>> Phase 4: Ansible - Configuring servers"
echo "--------------------------------------------"

cd "$ANSIBLE_DIR"

echo ">>> Testing connectivity..."
ansible all -i inventory.ini -m ping

echo ""
echo ">>> Running playbook..."
ansible-playbook -i inventory.ini kijanikiosk.yml

echo ""
echo "============================================"
echo "  Pipeline complete!"
echo "  $(date)"
echo "============================================"
echo ""
echo "SSH commands:"
echo "  API:      ssh -i $SSH_KEY $ANSIBLE_USER@$API_IP"
echo "  Payments: ssh -i $SSH_KEY $ANSIBLE_USER@$PAYMENTS_IP"
echo "  Logs:     ssh -i $SSH_KEY $ANSIBLE_USER@$LOGS_IP"
