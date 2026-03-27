#!/bin/bash

echo ">>> Installing packages"

BOOTSTRAPPER=$1

host_os()
{
  OS=`grep -E "^ID_LIKE=" /etc/os-release | cut -d '=' -f 2`
  if [[ -z "${OS}" ]]; then
    OS=`grep -E "^ID=" /etc/os-release | cut -d '=' -f 2`
  fi
  echo "$OS"
}

OS=`host_os`

case $OS in
"debian" | "ubuntu" )
  export DEBIAN_FRONTEND=noninteractive

  sed -i 's|us.archive.ubuntu.com|free.nchc.org.tw|g' /etc/apt/sources.list
  sed -i 's|security.ubuntu.com|free.nchc.org.tw|g' /etc/apt/sources.list
  if [ $OS == 'debian' ]
  then
    OS_VER=`grep -E "^VERSION_ID=" /etc/os-release | cut -d '=' -f 2`
    if [ $OS_VER == '"10"' ]
    then
      echo 'deb http://deb.debian.org/debian buster-backports main contrib non-free' > /etc/apt/sources.list.d/buster-backports.list
    elif [ $OS_VER == '"9"' ]
    then
      echo "deb http://deb.debian.org/debian/ unstable main" | sudo tee /etc/apt/sources.list.d/unstable.list
      echo -e "Package: *\nPin: release a=unstable\nPin-Priority: 150\n" | tee /etc/apt/preferences.d/limit-unstable
    fi
  fi

  apt-get update -y
  apt-get install -y git vim curl jq build-essential openssh-server net-tools
  apt-get install -y open-iscsi nfs-common snap
  snap install helm --classic

  # Use --flannel-backend=wireguard in K3s
  apt-get install -y wireguard
  ;;
*"opensuse"* )
  zypper ref
  zypper in -y apparmor-parser iptables wget
  zypper in -y git vim curl jq wget openssh net-tools
  #systemctl disable firewalld --now
  #zypper in -y nfs-utils nfs-client open-iscsi
  ;;
*"centos"* | *"fedora"* )
  #sed -i 's|vault.centos.org|mirror01.idc.hinet.net|g' /etc/yum.repos.d/CentOS-Linux-*

  #yum update -y
  yum install -y git vim curl jq wget openssh-clients openssh-server net-tools

  systemctl disable firewalld --now
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  systemctl restart sshd

  #yum install -y nfs-utils iscsi-initiator-utils
  yum install -y policycoreutils-python-utils container-selinux

  case $BOOTSTRAPPER in
  "k3s" )
    yum install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.1.stable.1/k3s-selinux-1.1-1.el8.noarch.rpm
    ;;
  "rke2" )
    yum install -y https://github.com/rancher/rke2-selinux/releases/download/v0.9.stable.1/rke2-selinux-0.9-1.el8.noarch.rpm
    ;;
  *)
    exit 1
  esac
  ;;
*)
  exit 1
  ;;
esac
