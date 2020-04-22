# Docker OpenSSH Server

Runs a sandboxed environment allowing SSH access without giving keys to the
entire server. Users only have access to the folders mapped and the processes
running inside this container.

> Inspired by https://hub.docker.com/r/linuxserver/openssh-server

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Usage](#usage)
  - [With Docker Compose](#with-docker-compose)
  - [With Docker](#with-docker)
- [Configuration](#configuration)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## Usage

Please refer to the documentation of the
[https://www.freebsd.org/cgi/man.cgi?sshd_config(5)](OpenSSH SSH daemon
configuration file) for more information on the SSH daemon's configuration
options.

### With Docker Compose

```yml
---
version: "3.7"

services:
  openssh-server:
    image: mei/openssh-server
    container_name: openssh
    hostname: openssh
    environment:
      SSH_ALLOW_TCP_FORWARDING: yes
      SSH_PERMIT_OPEN: db:5432
      SSH_PUBLIC_KEY: changeme
      TZ: Europe/London
      USER_NAME: openssh
      USER_UID: 2222
      USER_GID: 2222
    volumes:
      # Persist the server's host keys into a named volume so they are not
      # re-generated every time the container restarts (which would cause connection
      # warnings).
      - host_keys:/etc/openssh/host_keys
      # Optionally mount a custom authorized_keys file into the container (it must be
      # owned by the UID/GID specified with $USER_UID/$USER_GID, and have permissions
      # 400 or 600).
      - /custom/authorized_keys:/home/openssh/.ssh/authorized_keys:ro
    ports:
      - 2222:2222
    restart: unless-stopped

volumes:
  # Create a named volume to persist the server's host keys.
  host_keys:
```

### With Docker

```bash
# Create a named volume to persist the server's host keys (optional).
docker volume create openssh_host_keys

# Run the container (all flags are optional).
docker run \
  --name=openssh \
  --hostname=openssh \
  -e SSH_ALLOW_TCP_FORWARDING=yes \
  -e SSH_PERMIT_OPEN=db:5432 \
  -e SSH_PUBLIC_KEY=changeme \
  -e TZ=Europe/London \
  -e USER_NAME=openssh \
  -e USER_UID=2222 \
  -e USER_GID=2222 \
  -p 2222:2222 \
  -v openssh_host_keys:/etc/openssh/host_keys \
  -v /custom/authorized_keys:/home/openssh/.ssh/authorized_keys:ro \
  --restart unless-stopped \
  mei/openssh-server
```



## Configuration

The OpenSSH server can be dynamically configured through environment variables.
All variables are optional.

Variable                   | Default value                                     | Description
:------------------------- | :------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------
`SSH_ALLOW_TCP_FORWARDING` | `no`                                              | `AllowTcpForwarding` SSH daemon config option.
`SSH_PERMIT_OPEN`          | `none` (unless `$SSH_ALLOW_TCP_FOWARDING` is set) | `PermitOpen` SSH daemon config option.
`SSH_PUBLIC_KEY`           | -                                                 | SSH public key to grant access to (requires the `authorized_keys` file to be writable if you have mounted it).
`TZ`                       | -                                                 | Container timezone.
`USER_NAME`                | `openssh`                                         | Name of the user who can access the container.
`USER_UID`                 | `2222`                                            | UID of the user who can access the container.
`USER_GID`                 | `2222`                                            | GID of the group of the user who can access the container.
