FROM golang:1.18-alpine AS build

WORKDIR /src

RUN apk add --no-cache git openssh

RUN mkdir -p ~/.ssh && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Build from Gadgetry fork until PR is merged
# https://github.com/target/flottbot/pull/223
RUN git clone https://github.com/gadgetry-io/flottbot.git /src \
  && git checkout match-groups

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -a -ldflags "-s -w -X github.com/target/flottbot/version.Version=${VERSION} -X github.com/target/flottbot/version.GitHash=${GIT_HASH}" \
  -o flottbot ./cmd/flottbot

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive

# Install Apt Packages
RUN apt-get update \
  && apt-get install -y busybox curl unzip \
  && apt-get clean autoclean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Install https://github.com/stedolan/jq
RUN curl -sfLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
  && chmod +x /usr/local/bin/jq

# Install Nomad
RUN curl -sfLo - https://releases.hashicorp.com/nomad/1.2.3/nomad_1.2.3_linux_amd64.zip | busybox unzip -qd /usr/local/bin - \
 && chmod +x /usr/local/bin/nomad

# Setup user
RUN useradd --shell /usr/bin/bash --create-home bender

USER bender

COPY --from=build /src/flottbot /home/bender/flottbot
COPY --chown=bender:bender . /home/bender/config

WORKDIR /home/bender

CMD [ "/home/bender/flottbot" ]