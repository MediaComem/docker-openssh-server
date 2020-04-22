#!/usr/bin/with-contenv bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/00-vars.sh"

# Create the user & group.
addgroup -g "$USER_GID" "$USER_NAME"
adduser -h "$USER_HOME_DIR" -s /bin/bash -G "$USER_NAME" -D -u "$USER_UID" "$USER_NAME"
chmod 700 "$USER_HOME_DIR"

# Create the user's SSH directory if it does not exist (it may already be
# bind-mounted through a volume).
if ! test -f "$USER_SSH_DIR"; then
  (umask 077 && mkdir -p "$USER_SSH_DIR")
  chown "${USER_NAME}:${USER_NAME}" "$USER_SSH_DIR"
fi

# Create the user's SSH authorized_keys file if it does not exist (it may
# already be bind-mounted through a volume).
if ! test -f "$USER_SSH_AUTHORIZED_KEYS_FILE"; then
  (umask 066 && touch "$USER_SSH_AUTHORIZED_KEYS_FILE")
  chown "${USER_NAME}:${USER_NAME}" "$USER_SSH_AUTHORIZED_KEYS_FILE"
fi

echo "User name:       $USER_NAME"
echo "User UID & GID:  ${USER_UID}:${USER_GID}"
echo "User home:       $USER_HOME_DIR"
