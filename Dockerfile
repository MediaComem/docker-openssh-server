FROM alpine:3.11.5

LABEL maintainer="mei-admin@heig-vd.ch"

ENV S6_OVERLAY_VERSION=v1.21.8.0

RUN apk add --no-cache --virtual setup-dependencies ca-certificates wget && \
  wget -O /tmp/s6-overlay-amd64.tar.gz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz && \
  tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
  rm /tmp/s6-overlay-amd64.tar.gz && \
  apk add --no-cache \
    bash \
    openssh-server \
    openssh-sftp-server \
    tzdata \
  && \
  apk del setup-dependencies && \
  rm -rf /tmp/* && \
  mkdir -p /etc/openssh /var/run/openssh && \
  chmod 700 /etc/openssh /var/run/openssh && \
  mv /etc/ssh/sshd_config /etc/openssh/sshd_config && \
  chmod 644 /etc/openssh/sshd_config

COPY /fs /

ENTRYPOINT [ "/init" ]