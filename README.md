# Docker OpenSSH Server

Runs a sandboxed environment allowing SSH access without giving keys to the
entire server. Users only have access to the folders mapped and the processes
running inside this container.

> Inspired by https://hub.docker.com/r/linuxserver/openssh-server

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Usage](#usage)
  - [With Docker](#with-docker)
  - [With Docker Compose](#with-docker-compose)
- [Configuration](#configuration)
  - [Accessing data from the sandbox](#accessing-data-from-the-sandbox)
  - [Persisting the OpenSSH server's host keys](#persisting-the-openssh-servers-host-keys)
  - [Using a custom SSH `authorized_keys` file](#using-a-custom-ssh-authorized_keys-file)
  - [Customizing the SSH daemon's configuration file](#customizing-the-ssh-daemons-configuration-file)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## Usage

The [Configuration](#configuration) section describes the various environment
variables you can use to configure the OpenSSH server.

Please refer to the documentation of the [OpenSSH SSH daemon configuration
file](https://www.freebsd.org/cgi/man.cgi?sshd_config%285%29) for more
information on options related to the SSH daemon's configuration.

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
  mediacomem/openssh-server
```

### With Docker Compose

```yml
---
version: "3.7"

services:
  openssh-server:
    image: mediacomem/openssh-server
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



## Configuration

The OpenSSH server can be dynamically configured through environment variables.
All variables are optional.

Variable                   | Default value                                              | Description
:------------------------- | :--------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------
`SSH_ALLOW_TCP_FORWARDING` | `no`                                                       | `AllowTcpForwarding` SSH daemon config option.
`SSH_HOST_KEY_NAMES`       | `ssh_host_rsa_key,ssh_host_ecdsa_key,ssh_host_ed25519_key` | Comma-separated list of SSH host key files to read from the `/etc/openssh/host_keys` directory (configures a `HostKey` SSH daemon config option for each value).
`SSH_PERMIT_OPEN`          | `none` (unless `$SSH_ALLOW_TCP_FOWARDING` is set)          | `PermitOpen` SSH daemon config option.
`SSH_PUBLIC_KEY`           | -                                                          | Comma-separated list of SSH public keys to grant access to.
`TZ`                       | -                                                          | Container timezone.
`USER_NAME`                | `openssh`                                                  | Name of the user who can access the container.
`USER_UID`                 | `2222`                                                     | UID of the user who can access the container.
`USER_GID`                 | `2222`                                                     | GID of the group of the user who can access the container.

### Accessing data from the sandbox

You may use the `--volume` command-line option or the `volumes` Docker Compose
option to mount a host directory or a Docker volume that needs to be accessed in
the sandboxed environment. The container has access to nothing by default.

### Persisting the OpenSSH server's host keys

SSH host keys for the OpenSSH server will be found in the
`/etc/openssh/host_keys` directory. The container will generate these keys on
startup with `ssh-keygen -A` by default.

It is recommended that you mount a Docker volume at this path so that the host
keys are persisted across container restarts. Otherwise the container will
appear to change its identity after every restart, causing SSH connection
warnings on the client side.

Optionally, you may generate host keys yourself and mount them at this path
(either the key files themselves or the entire directory). The container will
not generate new keys if files are already present in the
`/etc/openssh/host_keys` directory.

In that case, note the following caveats:

* The key files must be owned by the user with the UID & GID specified through
  the `$USER_UID` & `$USER_GID` environment variables (`2222` by default).
* The key files must only be readable by their owner (i.e. permissions must be
  `400` or `600`).
* The `/etc/openssh/host_keys` directory must be traversable by the same user.
* The key filenames must match those configured through the
  `$SSH_HOST_KEY_NAMES` environment variable. The OpenSSH daemon's configuration
  file will be updated to load these specific keys.

### Using a custom SSH `authorized_keys` file

The OpenSSH server reads the file `/etc/openssh/authorized_keys` to know which
SSH public keys should be granted access to. This file is populated on startup
with the comma-separated values in the `$SSH_PUBLIC_KEY` environment variable if
available.

Optionally, you may mount this file from the host or from a Docker volume. You
may even mount it in read-only mode to prevent the user from modifying it.

In that case, note the following caveats:

* The file must be owned by the user with the UID & GID specified through
  the `$USER_UID` & `$USER_GID` environment variables (`2222` by default).
* The file must only be readable by its owner (i.e. permissions must be `400` or
  `600`).

### Customizing the SSH daemon's configuration file

The SSH daemon configuration file is located at `/etc/openssh/sshd_config` and
cannot be modified by the user who connects to the container over SSH (it is
owned by `root` and the `openssh` user, with permissions `640`).

If you extend this project's `Dockerfile`, you may put a pre-configured version
of this file at the correct path. However, note that it will be modified to fit
the configuration applied through environment variables.
