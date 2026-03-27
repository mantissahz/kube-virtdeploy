#!/bin/bash

echo ">>> Installing RKE2 agent"

RKE2_VERSION=$1
RKE2_TOKEN=$2
RKE2_URL=$3
KUBELET_LOG_LEVEL=$4
IP=$5

export INSTALL_RKE2_VERSION=${RKE2_VERSION}
export RKE2_TOKEN=${RKE2_TOKEN}
export INSTALL_RKE2_EXEC="--kubelet-arg v=${KUBELET_LOG_LEVEL}"

export INSTALL_RKE2_TYPE=agent

mkdir -p /etc/rancher/rke2

# For cis-1.5 profile
cat << EOF > /etc/sysctl.d/60-rke2-cis.conf
vm.panic_on_oom=0
vm.overcommit_memory=1
kernel.panic=10
kernel.panic_on_oops=1
EOF

sudo systemctl restart systemd-sysctl

cat <<EOF > /etc/rancher/rke2/config.yaml
server: ${RKE2_URL}
token: ${RKE2_TOKEN}
node-external-ip: ${IP}
node-ip: ${IP}
kubelet-arg: "v=${KUBELET_LOG_LEVEL}"
resolv-conf: "/etc/resolv.conf"
profile: "cis-1.6"
EOF

curl -sfL https://get.rke2.io | sh -

systemctl enable rke2-agent.service
systemctl start rke2-agent.service
