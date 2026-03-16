#!/bin/bash
set -euo pipefail

# Print K3s server token from controller node
# Usage: sudo bash scripts/get_k3s_token.sh

sudo cat /var/lib/rancher/k3s/server/node-token
