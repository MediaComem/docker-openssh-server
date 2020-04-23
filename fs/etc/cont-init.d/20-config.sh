#!/usr/bin/with-contenv bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/00-vars.sh"

# Configure logrotate to rotate the OpenSSH server's logs as the correct user.
sed -i "s/su openssh openssh/su ${USER_NAME} ${USER_NAME}/g" /etc/logrotate.d/openssh

# Create directories and files for the OpenSSH server.
mkdir -p /etc/openssh/host_keys /var/{log,run}/openssh
chmod 700 /etc/openssh /etc/openssh/host_keys /var/{log,run}/openssh
chown "${USER_NAME}:${USER_NAME}" /etc/openssh /etc/openssh/host_keys /var/{log,run}/openssh

# Create the SSH daemon's sshd_config file if it doesn't exist yet.
if ! test -f /etc/openssh/sshd_config; then
  mv /etc/ssh/sshd_config /etc/openssh/sshd_config
  chmod 640 /etc/openssh/sshd_config
  chown "root:${USER_NAME}" /etc/openssh/sshd_config
else
  rm /etc/ssh/sshd_config
fi

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
