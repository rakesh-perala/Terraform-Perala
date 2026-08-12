#!/bin/bash

set -e

echo "======================================"
echo "Installing Terraform and AWS CLI"
echo "======================================"

sudo apt-get update -y

sudo apt-get install -y \
  curl \
  wget \
  unzip \
  gnupg \
  software-properties-common \
  lsb-release


# ======================================
# Terraform
# ======================================

echo "Installing Terraform..."

wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
| sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update -y

sudo apt-get install -y terraform


# ======================================
# AWS CLI V2
# ======================================

echo "Installing AWS CLI v2..."

cd /tmp

curl -fsSL \
"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o awscliv2.zip

unzip -q awscliv2.zip

sudo ./aws/install

rm -rf aws awscliv2.zip


# ======================================
# Verification
# ======================================

echo ""
echo "======================================"
echo "Terraform Version"
echo "======================================"

terraform version

echo ""
echo "======================================"
echo "AWS CLI Version"
echo "======================================"

aws --version

echo ""
echo "======================================"
echo "Installation Completed"
echo "======================================"
