#!/bin/bash
set -e

echo "Starting RKE2 installation for additional servers..."

# 1. Create RKE2 config directory
sudo mkdir -p /etc/rancher/rke2/

# 2. Generate Config with dynamic TLS-SAN
sudo tee /etc/rancher/rke2/config.yaml > /dev/null <<EOF
server: https://${private_ip}:9345
token: ${TOKEN}
tls-san:
  - ${public_ip}
EOF


# 3. Install specific version of RKE2
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_VERSION=${rke2_version} sh -

# 4. Enable and Start Service
sudo systemctl enable --now rke2-server

# 5. Wait for Readiness
echo "Waiting for RKE2-server to be active..."
while ! sudo systemctl is-active --quiet rke2-server; do 
    sleep 10
done

# 6. Apply Local Path Provisioner
# Note the double dollar sign ($$) to escape the Bash variable from Terraform
sudo sh -c "export PATH=\$$PATH:/var/lib/rancher/rke2/bin && \
            export KUBECONFIG=/etc/rancher/rke2/rke2.yaml && \
            kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml"


echo "RKE2 installation for additional server ${private_ip} is completed."