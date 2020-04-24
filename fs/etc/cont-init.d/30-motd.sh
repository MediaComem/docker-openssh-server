#!/usr/bin/with-contenv bash
set -e

# Customize the MOTD.
if test -n "$MOTD"; then
  printf "${MOTD}\n\n" > /etc/motd
fi
