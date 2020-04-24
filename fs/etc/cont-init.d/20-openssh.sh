#!/usr/bin/with-contenv bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/00-vars.sh"

# Set ownership of OpenSSH server directories.
chown "${USER_NAME}:${USER_NAME}" /etc/openssh /var/run/openssh

# Create the SSH host keys directory if it doesn't exist yet.
if ! test -d /etc/openssh/host_keys; then
  (umask 077 && mkdir /etc/openssh/host_keys)
  chown "${USER_NAME}:${USER_NAME}" /etc/openssh/host_keys
fi

# Set the ownership and permissions of the SSH daemon's configuration file.
# Do not stop if it fails; it may be a read-only mount.
chmod 640 /etc/openssh/sshd_config && \
  chown "root:${USER_NAME}" /etc/openssh/sshd_config || \
  echo "Skipped modification of /etc/openssh/sshd_config"

# Create the SSH authorized_keys file if it doesn't exist yet.
if ! test -f /etc/openssh/authorized_keys; then
  (umask 066 && touch /etc/openssh/authorized_keys)
  chown "${USER_NAME}:${USER_NAME}" /etc/openssh/authorized_keys
fi

# Delete OpenSSH keywords that are configured below.
for keyword in \
  AuthorizedKeysFile \
  AllowTcpForwarding \
  HostKey \
  PasswordAuthentication \
  PermitOpen \
  PidFile \
; do
  sed -i "s/^\(${keyword}\)/#\1/g" /etc/openssh/sshd_config
done

# Configure the path to the SSH authorized_keys file.
echo "AuthorizedKeysFile /etc/openssh/authorized_keys" >> /etc/openssh/sshd_config

# Allow/deny TCP forwarding.
if test -n "$SSH_PERMIT_OPEN"; then
  echo "AllowTcpForwarding ${SSH_ALLOW_TCP_FORWARDING:-yes}" >> /etc/openssh/sshd_config
  echo "PermitOpen $SSH_PERMIT_OPEN" >> /etc/openssh/sshd_config
elif test -n "$SSH_ALLOW_TCP_FORWARDING"; then
  echo "AllowTcpForwarding ${SSH_ALLOW_TCP_FORWARDING}" >> /etc/openssh/sshd_config
else
  echo "AllowTcpForwarding no" >> /etc/openssh/sshd_config
  echo "PermitOpen none" >> /etc/openssh/sshd_config
fi

# Configure host keys.
OLD_IFS=$IFS
IFS=','
for key_name in ${SSH_HOST_KEY_NAMES:-ssh_host_rsa_key,ssh_host_ecdsa_key,ssh_host_ed25519_key}; do
  echo "HostKey /etc/openssh/host_keys/${key_name}" >> /etc/openssh/sshd_config
done
IFS="$OLD_IFS"

# Disable password authentication.
echo "PasswordAuthentication no" >> /etc/openssh/sshd_config

# Configure the location of the OpenSSH server's PID file.
echo "PidFile /var/run/openssh/sshd.pid" >> /etc/openssh/sshd_config

# Generate host SSH keys.
if test "$(ls -1 -A /etc/openssh/host_keys|wc -l)" -eq 0; then
  ssh-keygen -A
  mv /etc/ssh/ssh_host_*_key* /etc/openssh/host_keys/
  chmod 400 /etc/openssh/host_keys/ssh_host_*_key*
  chown "${USER_NAME}:${USER_NAME}" /etc/openssh/host_keys/ssh_host_*_key*
fi

# Add public key(s) from environment variable if specified (requires the file to
# be writable by the user).
if test -n "$SSH_PUBLIC_KEY"; then
  OLD_IFS=$IFS
  IFS=','
  for public_key in "$SSH_PUBLIC_KEY"; do
    echo "$public_key" >> /etc/openssh/authorized_keys
  done
  IFS="$OLD_IFS"
  echo "Public key from \$PUBLIC_KEY authorized"
fi
