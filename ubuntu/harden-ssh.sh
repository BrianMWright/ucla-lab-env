#!/usr/bin/env bash
set -euo pipefail
CONF="/etc/ssh/sshd_config.d/99-local-hardening.conf"
sudo install -m 0644 /dev/null "$CONF"
cat <<EOF | sudo tee "$CONF" >/dev/null
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
EOF
sudo sed -i "s/^[[:space:]]*PasswordAuthentication[[:space:]]\\+yes/PasswordAuthentication no/" \
  /etc/ssh/sshd_config.d/50-cloud-init.conf 2>/dev/null || true
sudo sshd -t
sudo systemctl reload ssh
sudo sshd -T | egrep "passwordauthentication|pubkeyauthentication|kbdinteractive|challenge|permitrootlogin" || true
echo "✅ SSH hardening applied (key-only)."
