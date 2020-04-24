#!/usr/bin/with-contenv bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DIR}/00-vars.sh"

# Create the user & group.
addgroup -g "$USER_GID" "$USER_NAME"
adduser -h "$USER_HOME_DIR" -s /bin/bash -G "$USER_NAME" -D -u "$USER_UID" "$USER_NAME"
chmod 700 "$USER_HOME_DIR"

# Log user information to standard output.
echo "User name:       $USER_NAME"
echo "User UID & GID:  ${USER_UID}:${USER_GID}"
echo "User home:       $USER_HOME_DIR"
