#!/bin/bash
# Se ejecuta una sola vez al crear la instancia (cloud-init).
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io docker-compose-v2 curl

systemctl enable --now docker
usermod -aG docker ubuntu

mkdir -p /opt/logiflow /opt/logiflow-staging
chown ubuntu:ubuntu /opt/logiflow /opt/logiflow-staging
