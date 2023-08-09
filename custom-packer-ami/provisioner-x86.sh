#!/usr/bin/env bash
sleep 20
sudo yum upgrade -y
sleep 10
sudo yum install docker -y
sudo systemctl enable docker
sudo systemctl restart docker
sudo systemctl enable crond

# Docker-Compose Binary
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /bin/docker-compose
sudo chmod +x /bin/docker-compose

# ECR Login

# Node Exporter

# Process Exporter
