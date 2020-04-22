#!/usr/bin/with-contenv bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/00-vars.sh"

# Configure logrotate to rotate the OpenSSH server's logs as the correct user.
sed -i "s/su openssh openssh/su ${USER_NAME} ${USER_NAME}/g" /etc/logrotate.d/openssh

# Create directories for the OpenSSH server.
(umask 077 && mkdir -p /etc/openssh/host_keys /var/{log,run}/openssh)
chown "${USER_NAME}:${USER_NAME}" /etc/openssh /etc/openssh/host_keys /var/{log,run}/openssh

# Delete OpenSSH keywords that are configured below.
for keyword in \
  AllowTcpForwarding \
  HostKey \
  PasswordAuthentication \
  PermitOpen \
  PidFile \
; do
  sed -i "/^${keyword}/d" /etc/ssh/sshd_config
done

# Allow/deny TCP forwarding.
if test -n "$SSH_PERMIT_OPEN"; then
  echo "AllowTcpForwarding ${SSH_ALLOW_TCP_FORWARDING:-yes}" >> /etc/ssh/sshd_config
  echo "PermitOpen $SSH_PERMIT_OPEN" >> /etc/ssh/sshd_config
elif test -n "$SSH_ALLOW_TCP_FORWARDING" ]; then
  echo "AllowTcpForwarding ${SSH_ALLOW_TCP_FORWARDING}" >> /etc/ssh/sshd_config
else
  echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
  echo "PermitOpen none" >> /etc/ssh/sshd_config
fi

# Configure host keys.
echo "HostKey /etc/openssh/host_keys/ssh_host_rsa_key" >> /etc/ssh/sshd_config
echo "HostKey /etc/openssh/host_keys/ssh_host_ecdsa_key" >> /etc/ssh/sshd_config
echo "HostKey /etc/openssh/host_keys/ssh_host_ed25519_key" >> /etc/ssh/sshd_config

# Disable password authentication.
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# Configure the location of the OpenSSH server's PID file.
echo "PidFile /var/run/openssh/sshd.pid" >> /etc/ssh/sshd_config

# Generate host SSH keys.
ssh-keygen -A
mv /etc/ssh/ssh_host_*_key* /etc/openssh/host_keys/
chmod 400 /etc/openssh/host_keys/ssh_host_*_key*
chown "${USER_NAME}:${USER_NAME}" /etc/openssh/host_keys/ssh_host_*_key*

# Add public key from environment variable if specified (requires the file to be
# writable by the user).
if test -n "$SSH_PUBLIC_KEY"; then
  echo "$SSH_PUBLIC_KEY" >> "$USER_SSH_AUTHORIZED_KEYS_FILE"
  echo "Public key from \$PUBLIC_KEY authorized"
fi
