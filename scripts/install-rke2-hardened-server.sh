#!/bin/bash

echo ">>> Installing RKE2 server"

RKE2_VERSION=$1
RKE2_TOKEN=$2
KUBELET_LOG_LEVEL=$3
IP=$4

echo "export PATH=$PATH:/var/lib/rancher/rke2/bin" >> /root/.bashrc
echo "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml" >> /root/.bashrc
echo "export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml" >> /root/.bashrc

mkdir -p /etc/rancher/rke2

# For cis-1.5 profile
cat << EOF > /etc/sysctl.d/60-rke2-cis.conf
vm.panic_on_oom=0
vm.overcommit_memory=1
kernel.panic=10
kernel.panic_on_oops=1
EOF

sudo systemctl restart systemd-sysctl

useradd -r -c "etcd user" -s /sbin/nologin -M etcd

cat <<EOF > /etc/rancher/rke2/config.yaml
token: ${RKE2_TOKEN}
node-external-ip: ${IP}
node-ip: ${IP}
kubelet-arg: "v=${KUBELET_LOG_LEVEL}"
resolv-conf: "/etc/resolv.conf"
profile: "cis-1.6"
EOF

export INSTALL_RKE2_VERSION=${RKE2_VERSION}

curl -sfL https://get.rke2.io | sh -

systemctl enable rke2-server.service
systemctl start rke2-server.service
