#!/usr/bin/env bash

USER=$(whoami)
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/completions
mkdir -p ~/.local/man/man{1,2,3,4,5,6,7,8,9}
mkdir -p ~/.config/k9s
if [ ! -f ~/.config/.disk ]; then
  if [ -f /tmp/.disk ]; then
    mv /tmp/.disk ~/.config
  else
    echo "Did not detech Disk Device name!!"
    echo "LXD profile may be incorrect configured. Proceed at your own risk!!"
  fi
fi
curl -sSL -o ~/.config/k9s/skin.yml https://raw.githubusercontent.com/derailed/k9s/master/skins/dracula.yml
CONTAINERD_LATEST=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest)
CONTAINERD_VER=$(echo -E "$CONTAINERD_LATEST" | jq -M ".tag_name" | tr -d '"' | sed 's/.*v\(.*\)/\1/')
CRUN_LATEST=$(curl -s https://api.github.com/repos/containers/crun/releases/latest)
CRUN_VER=$(echo -E "$CRUN_LATEST" | jq -M ".tag_name" | tr -d '"' | sed 's/.*v\(.*\)/\1/')

# Install get-fzf.sh

cat <<'EOF' > ~/.local/bin/get-fzf.sh
#!/usr/bin/env bash

echo
echo "****************************"
echo "*                          *"
echo "* Download and Install fzf *"
echo "*                          *"
echo "****************************"
echo
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install
EOF

# Install get-cilium.sh

cat <<'EOF' > ~/.local/bin/get-cilium.sh
#!/usr/bin/env bash

echo
echo "*******************************"
echo "*                             *"
echo "* Download and Install Cilium *"
echo "*                             *"
echo "*******************************"
echo
# Ref: https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
tar xzvfC cilium-linux-amd64.tar.gz ~/.local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
EOF

# Install get-hubble.sh

cat <<'EOF' > ~/.local/bin/get-hubble.sh
#!/usr/bin/env bash

echo
echo "*******************************"
echo "*                             *"
echo "* Download and Install Hubble *"
echo "*                             *"
echo "*******************************"
echo
# Ref: https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
export HUBBLE_VERSION
curl -L --remote-name-all https://github.com/cilium/hubble/releases/download/"$HUBBLE_VERSION"/hubble-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
tar xzvfC hubble-linux-amd64.tar.gz ~/.local/bin
rm hubble-linux-amd64.tar.gz{,.sha256sum}
EOF

# Install get-krew.sh
cat <<'EOF' > ~/.local/bin/get-krew.sh
#!/usr/bin/env bash

echo
echo "*****************************"
echo "*                           *"
echo "* Download and Install Krew *"
echo "*                           *"
echo "*****************************"
echo
# Ref: https://krew.sigs.k8s.io/docs/user-guide/setup/install/
if [ ! -d ~/.krew ]; then
  mkdir ~/.krew
fi
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
EOF

# Install get-helm.sh
cat <<'EOF' > ~/.local/bin/get-helm.sh
#!/usr/bin/env bash

echo
echo "*****************************"
echo "*                           *"
echo "* Download and Install Helm *"
echo "*                           *"
echo "*****************************"
echo
curl -fsSL -o ~/.local/bin/get-helm-3.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sed -i "/HELM_INSTALL_DIR/s#/usr/local#$HOME/.local#" ~/.local/bin/get-helm-3.sh
sed -i "/runAsRoot cp/s#runAsRoot cp#cp#" ~/.local/bin/get-helm-3.sh
chmod +x ~/.local/bin/get-helm-3.sh
~/.local/bin/get-helm-3.sh
EOF

# Install VirtualBox
cat <<'EOF' > ~/.local/bin/get-vb.sh
#!/usr/bin/env bash

echo
echo "***********************************"
echo "*                                 *"
echo "* Download and Install VirtualBox *"
echo "*                                 *"
echo "***********************************"
echo

curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /usr/share/keyrings/oracle_vbox_2016.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/oracle_vbox_2016.gpg] \
  http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | \
  sudo tee /etc/apt/sources.list.d/oracle_vbox.list

sudo apt update
sudo apt install virtualbox mkisofs -y
EOF

# Install Vagrant
cat <<'EOF' > ~/.local/bin/get-vagrant.sh
#!/usr/bin/env bash

pushd () {
    command pushd "$@" > /dev/null || exit
}

popd () {
    command popd > /dev/null || exit
}

echo
echo "********************************"
echo "*                              *"
echo "* Download and Install Vagrant *"
echo "*                              *"
echo "********************************"
echo
pushd .
cd /tmp || exit
LATEST=$(curl -SL https://releases.hashicorp.com/vagrant | grep ">vagrant_.*<" | sed 's#^.*>vagrant_\(.*\)<.*#\1#' | head -1)
curl -sSLO https://releases.hashicorp.com/vagrant/"$LATEST"/vagrant_"$LATEST"_x86_64.deb
sudo apt install ./vagrant_"$LATEST"_x86_64.deb
rm ./vagrant_"$LATEST"_x86_64.deb
popd || exit
vagrant plugin install vagrant-vbguest
EOF

# Create VBX cluster
cat <<'EOF' > ~/.local/bin/create-vbx-cluster.sh
#!/usr/bin/env bash

# Ref: https://github.com/scriptcamp/vagrant-kubeadm-kubernetes/blob/main/scripts/master.sh

if [ -f kubeadm-init.out ]; then
  rm kubeadm-init.out
fi
if [ -f config ]; then
  rm config
fi

cat <<MYEOF > cloud.cfg
#cloud-config

apt:
  preserve_sources_list: false

  primary:
    - arches:
      - amd64
      uri: "http://mirror.0x.sg/ubuntu/"

  security:
    - arches:
      - amd64
      uri: "http://security.ubuntu.com/ubuntu"

  sources:
    kubernetes.list:
      source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
      keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071

packages:
 - apt-transport-https
 - jq
 - kubeadm
 - kubelet
 - containerd

package_update: true

package_upgrade: true

package_reboot_if_required: true

mount_default_fields: [ None, None, "auto", "defaults,nobootwait", "0", "2" ]

locale: en_SG.UTF-8
locale_configfile: /etc/default/locale

resize_rootfs: True

final_message: "The system is finally up, after $UPTIME seconds"

timezone: Asia/Singapore

ntp:
  enabled: true
manual_cache_clean: True

write_files:
- content: |
      overlay
      br_netfilter
      nf_conntrack
  owner: root:root
  path: /etc/modules-load.d/containerd.conf
  permissions: '0644'

- content: |
      options nf_conntrack hashsize=32768
  owner: root:root
  path: /etc/modprobe.d/containerd.conf
  permissions: '0644'

- content: |
      net.bridge.bridge-nf-call-iptables=1
      net.ipv4.ip_forward=1
      net.bridge.bridge-nf-call-ip6tables=1
  path: /etc/sysctl.d/99-sysctl.conf
  append: true

- content: |
      127.0.0.1 localhost
      10.253.253.11 vbx-ctrlp-1
      10.253.253.12 vbx-wrker-1
      10.253.253.13 vbx-wrker-2

      # The following lines are desirable for IPv6 capable hosts
      ::1 ip6-localhost ip6-loopback
      fe00::0 ip6-localnet
      ff00::0 ip6-mcastprefix
      ff02::1 ip6-allnodes
      ff02::2 ip6-allrouters
      ff02::3 ip6-allhosts
  owner: root:root
  path: /etc/hosts
  permissions: '0644'

runcmd:
 - apt-get -y purge nano
 - apt-get -y autoremove
 - modprobe br_netfilter
 - modprobe nf_conntrack
 - sysctl --system
 - mkdir -p /etc/containerd
 - containerd config default | tee /etc/containerd/config.toml
 - systemctl restart containerd
MYEOF

cat <<MYEOF > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    CtrlpCount = 1

    (1..CtrlpCount).each do |i|
    config.vm.define "vbx-ctrlp-1" do |ctrlp|
            ctrlp.vm.box = "ubuntu/focal64"
            ctrlp.vm.network :private_network, ip: "10.253.253.1#{i}"
            ctrlp.vm.hostname = "vbx-ctrlp-1"
            ctrlp.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            ctrlp.vm.provider :virtualbox do |v|
                v.memory = 2048
                v.cpus = 2
            end
        end
    end

    NodeCount = 2

    (1..NodeCount).each do |i|
        config.vm.define "vbx-wrker-#{i}" do |node|
            node.vm.box = "ubuntu/focal64"
            node.vm.network :private_network, ip: "10.253.253.1#{i+CtrlpCount}"
            node.vm.hostname = "vbx-wrker-#{i}"
            node.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            node.vm.provider :virtualbox do |v|
                v.memory = 1536
                v.cpus = 2
            end
        end
    end

    config.vm.box_check_update = false
    config.vbguest.auto_update = false
    config.vm.boot_timeout = 600
end
MYEOF

VAGRANT_EXPERIMENTAL="cloud_init,disks" vagrant up
vagrant ssh vbx-ctrlp-1 -c "sudo kubeadm init \
                              --apiserver-advertise-address=10.253.253.11 \
                              --apiserver-cert-extra-sans=10.253.253.11 \
                              --node-name vbx-ctrlp-1 \
                              --pod-network-cidr=192.168.0.0/16 \
                              --upload-certs | \
                              tee kubeadm-init.out" 2> /dev/null
vagrant ssh vbx-ctrlp-1 -c "mv kubeadm-init.out /vagrant" 2> /dev/null
vagrant ssh vbx-ctrlp-1 -c "sudo cp /etc/kubernetes/admin.conf /vagrant/config" 2> /dev/null
cp config ~/.kube/config
vagrant ssh vbx-wrker-1 -c "sudo $(tail -2 kubeadm-init.out | tr -d '\\\n')" 2> /dev/null
vagrant ssh vbx-wrker-2 -c "sudo $(tail -2 kubeadm-init.out | tr -d '\\\n')" 2> /dev/null
curl -sSL https://docs.projectcalico.org/manifests/calico.yaml | sed 's#policy/v1beta1#policy/v1#' | kubectl apply -f -
rm cloud.cfg Vagrantfile
EOF

# Stop VBX cluster
#!/usr/bin/env bash
cat <<'EOF' > ~/.local/bin/stop-vbx-cluster.sh
#!/usr/bin/env bash
cat <<MYEOF > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    CtrlpCount = 1

    (1..CtrlpCount).each do |i|
    config.vm.define "vbx-ctrlp-1" do |ctrlp|
            ctrlp.vm.box = "ubuntu/focal64"
            ctrlp.vm.network :private_network, ip: "10.253.253.1#{i}"
            ctrlp.vm.hostname = "vbx-ctrlp-1"
            ctrlp.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            ctrlp.vm.provider :virtualbox do |v|
                v.memory = 2048
                v.cpus = 2
            end
        end
    end

    NodeCount = 2

    (1..NodeCount).each do |i|
        config.vm.define "vbx-wrker-#{i}" do |node|
            node.vm.box = "ubuntu/focal64"
            node.vm.network :private_network, ip: "10.253.253.1#{i+CtrlpCount}"
            node.vm.hostname = "vbx-wrker-#{i}"
            node.vm.cloud_init :user_data, content_type: "text/cloud-config", path: "cloud.cfg"
            node.vm.provider :virtualbox do |v|
                v.memory = 1536
                v.cpus = 2
            end
        end
    end

    config.vm.box_check_update = false
    config.vbguest.auto_update = false
    config.vm.boot_timeout = 600
end
MYEOF
vagrant destroy -f
rm Vagrantfile
EOF

# Install k-apply.sh
cat <<'EOF' > ~/.local/bin/k-apply.sh
#!/usr/bin/env bash

echo
echo "****************************************************************************************"
echo "*                                                                                      *"
echo "* Deploy Metrics Server (abridged version), MetalLB & Local-Path-Provisioner (Rancher) *"
echo "*                                                                                      *"
echo "****************************************************************************************"
echo
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/metrics-server-helm-chart-3.7.0/components.yaml
kubectl apply -f https://raw.githubusercontent.com/tsanghan/content-cka-resources/master/metrics-server-components.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.11.0/manifests/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
EOF

cat <<'EOF' > ~/.local/bin/ingress-nginx.sh
#!/usr/bin/env bash

echo
echo "*****************************************************************************************"
echo "*                                                                                       *"
echo "* Deploy Ingress-NGINX Controller (Kubernetes Ingress) *"
echo "*                                                                                       *"
echo "*****************************************************************************************"
echo
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml
EOF

cat <<'EOF' > ~/.local/bin/nginx-ap-ingress.sh
#!/usr/bin/env bash
iface=$(ip link | grep ens | awk '{print $2}' | tr -d ':')
if [ "$iface" == "" ]; then
  echo "Interface ens* no found!!"
  exit 127
fi
IP=$(ip a s "$iface" | head -3 | tail -1 | awk '{print $2}' | tr -d '/24$')
while getopts "p" o; do
    case "$o" in
        p)
            private="true"
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

echo
echo "**************************************"
echo "*                                    *"
echo "* Deploy F5 NGINX Ingress Controller *"
echo "*                                    *"
echo "**************************************"
echo
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/ns-and-sa.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/rbac/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/rbac/ap-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/default-server-secret.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/nginx-config.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/ingress-class.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_policies.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/k8s.nginx.org_globalconfigurations.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/appprotect.f5.com_aplogconfs.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/appprotect.f5.com_appolicies.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v2.0.3/deployments/common/crds/appprotect.f5.com_apusersigs.yaml
if [ "$private" == "true" ]; then
  curl -sSL https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/deployment/nginx-plus-ingress.yaml |\
    sed '/image\:/s#\: #\: '"$IP"'/nginx-ic-nap/#' |\
    sed '/enable-app-protect$/s%#-% -%'|\
    kubectl apply -f -
else
  kubectl create secret docker-registry regcred \
    --docker-server=private-registry.nginx.com \
    --docker-username="$(/usr/bin/cat ~/.local/share/nginx-repo.jwt)" \
    --docker-password=none -n nginx-ingress
  curl -sSL https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/deployment/nginx-plus-ingress.yaml |\
    sed '/image\:/s#\: #\: private-registry.nginx.com/nginx-ic-nap/#' |\
    sed '/enable-app-protect$/s%#-% -%'|\
    kubectl apply -f -
fi
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/master/deployments/service/loadbalancer.yaml
EOF

cat <<'MYEOF' > ~/.local/bin/prepare-lxd.sh
#!/usr/bin/env bash

CONTAINERD_LATEST=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest)
CONTAINERD_VER=$(echo -E "$CONTAINERD_LATEST" | jq -M ".tag_name" | tr -d '"' | sed 's/.*v\(.*\)/\1/')
CRUN_LATEST=$(curl -s https://api.github.com/repos/containers/crun/releases/latest)
CRUN_VER=$(echo -E "$CRUN_LATEST" | jq -M ".tag_name" | tr -d '"' | sed 's/.*v\(.*\)/\1/')
KUBE_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt | sed 's/v\(.*\)/\1/')
iface=$(ip link | egrep "ens|eth" | awk '{print $2}' | tr -d ':')
if [ "$iface" == "" ]; then
  echo "Interface ens* or eth* not found!!"
  exit 127
fi
PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';')
if [ "$PROXY" != "" ]; then
  # Ref: below PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')
  IP=$(echo "$PROXY" | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')
else
  IP=$(ip a s "$iface" | head -3 | tail -1 | awk '{print $2}' | tr -d '/24$')
fi

while getopts "s" o; do
    case "$o" in
        s)
            slim="true"
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

for profile in lb k8s-cloud-init k8s-cloud-init-local-registries;
do
  exists=$(lxc profile ls | grep "$profile")
  if [ "$exists" != "" ]; then
    lxc profile delete "$profile"
  fi
done

cat <<EOF | sudo lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: 10.254.254.254/24
    ipv4.dhcp.gateway: 10.254.254.254
    ipv4.dhcp.ranges: 10.254.254.1-10.254.254.239
    ipv4.nat: "true"
    ipv6.address: none
  description: ""
  name: lxdbr0
  type: ""
storage_pools:
- config:
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF

k8s_cloud_init=$(lxc profile ls | grep k8s-cloud-init)
if [ "$k8s_cloud_init"  == "" ]; then
  lxc profile create k8s-cloud-init

  cat <<EOF > /tmp/lxd-profile-k8s-cloud-init
  config:
    linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay
    raw.lxc: |-
      lxc.apparmor.profile=unconfined
      lxc.cap.drop=
      lxc.cgroup.devices.allow=a
      lxc.mount.auto=proc:rw sys:rw cgroup:rw
      lxc.seccomp.profile=
    security.nesting: "true"
    security.privileged: "true"
    user.user-data: |
      #cloud-config
      apt:
        preserve_sources_list: false
        primary:
          - arches:
            - amd64
            uri: "http://archive.ubuntu.com/ubuntu/"
        security:
          - arches:
            - amd64
            uri: "http://security.ubuntu.com/ubuntu"
EOF

  PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';')
  if [ "$PROXY" != "" ]; then
    echo "        proxy: $PROXY" >> /tmp/lxd-profile-k8s-cloud-init
  fi

  cat <<EOF >> /tmp/lxd-profile-k8s-cloud-init
        sources:
          kubernetes.list:
            source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
            keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
      packages:
        - apt-transport-https
        - ca-certificates
        - containerd
        - curl
        - kubeadm=$KUBE_VER-00
        - kubelet=$KUBE_VER-00
        - jq
      package_update: false
      package_upgrade: false
      package_reboot_if_required: false
      locale: en_SG.UTF-8
      locale_configfile: /etc/default/locale
      timezone: Asia/Singapore
      write_files:
      - content: |
          [Unit]
          Description=Mount Make Rshare

          [Service]
          ExecStart=/bin/mount --make-rshare /

          [Install]
          WantedBy=multi-user.target
        owner: root:root
        path: /etc/systemd/system/mount-make-rshare.service
        permissions: '0644'
      - content: |
          runtime-endpoint: unix:///run/containerd/containerd.sock
          image-endpoint: unix:///run/containerd/containerd.sock
          timeout: 10
        owner: root:root
        path: /etc/crictl.yaml
        permissions: '0644'
      runcmd:
        - apt-get -y purge nano
        - apt-get -y autoremove
        - systemctl enable mount-make-rshare
        - mkdir -p /etc/containerd
        - containerd config default | sed '/config_path/s#""#"/etc/containerd/certs.d"#' | tee /etc/containerd/config.toml
        - systemctl restart containerd
        - kubeadm config images pull
        - ctr oci spec | tee /etc/containerd/cri-base.json
      power_state:
        delay: "+1"
        mode: poweroff
        message: Bye Bye
        timeout: 10
        condition: True
  description: ""
  devices:
    _dev_sda1:
      path: /dev/sda1
      source: /dev/sda1
      type: unix-block
    aadisable:
      path: /sys/module/nf_conntrack/parameters/hashsize
      source: /dev/null
      type: disk
    aadisable1:
      path: /sys/module/apparmor/parameters/enabled
      source: /dev/null
      type: disk
    boot_dir:
      path: /boot
      source: /boot
      type: disk
    dev_kmsg:
      path: /dev/kmsg
      source: /dev/kmsg
      type: unix-char
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
EOF

  sed "s#/dev/sda1#$(cat ~/.config/.disk)#" < /tmp/lxd-profile-k8s-cloud-init | lxc profile edit k8s-cloud-init
  rm /tmp/lxd-profile-k8s-cloud-init
fi

k8s_cloud_init_local_registries=$(lxc profile ls | grep k8s-cloud-init-local-registries)
if [ "$k8s_cloud_init_local_registries"  == "" ]; then
  lxc profile create k8s-cloud-init-local-registries

  cat <<EOF > /tmp/lxd-profile-k8s-cloud-init-local-registries
  config:
    linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay
    raw.lxc: |-
      lxc.apparmor.profile=unconfined
      lxc.cap.drop=
      lxc.cgroup.devices.allow=a
      lxc.mount.auto=proc:rw sys:rw cgroup:rw
      lxc.seccomp.profile=
    security.nesting: "true"
    security.privileged: "true"
    user.user-data: |
      #cloud-config
      apt:
        preserve_sources_list: false
        primary:
          - arches:
            - amd64
            uri: "http://archive.ubuntu.com/ubuntu/"
        security:
          - arches:
            - amd64
            uri: "http://security.ubuntu.com/ubuntu"
EOF

  # KUBE_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt | sed 's/v\(.*\)/\1/')
  PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';')
  if [ "$PROXY" != "" ]; then
    echo "        proxy: $PROXY" >> /tmp/lxd-profile-k8s-cloud-init-local-registries
  fi

  cat <<EOF >> /tmp/lxd-profile-k8s-cloud-init-local-registries
        sources:
          kubernetes.list:
            source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
            keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - kubeadm=$KUBE_VER-00
        - kubelet=$KUBE_VER-00
        - jq
      package_update: false
      package_upgrade: false
      package_reboot_if_required: false
      locale: en_SG.UTF-8
      locale_configfile: /etc/default/locale
      timezone: Asia/Singapore
      write_files:
      - content: |
          [Unit]
          Description=Mount Make Rshare

          [Service]
          ExecStart=/bin/mount --make-rshare /

          [Install]
          WantedBy=multi-user.target
        owner: root:root
        path: /etc/systemd/system/mount-make-rshare.service
        permissions: '0644'
      - content: |
          runtime-endpoint: unix:///run/containerd/containerd.sock
          image-endpoint: unix:///run/containerd/containerd.sock
          timeout: 10
        owner: root:root
        path: /etc/crictl.yaml
        permissions: '0644'
      - content: |
          server = "https://docker.io"

          [host."http://$IP:5000"]
            capabilities = ["pull", "resolve"]
        owner: root:root
        path: /etc/containerd/certs.d/docker.io/hosts.toml
        permissions: '0644'
      - content: |
          server = "https://k8s.gcr.io"

          [host."http://$IP:5001"]
            capabilities = ["pull", "resolve"]
        owner: root:root
        path: /etc/containerd/certs.d/k8s.gcr.io/hosts.toml
        permissions: '0644'
      - content: |
          server = "https://quay.io"

          [host."http://$IP:5002"]
            capabilities = ["pull", "resolve"]
        owner: root:root
        path: /etc/containerd/certs.d/quay.io/hosts.toml
        permissions: '0644'
      - content: |
          server = "http://$IP"

          [host."http://$IP:6000"]
            capabilities = ["pull", "resolve"]
        owner: root:root
        path: /etc/containerd/certs.d/$IP/hosts.toml
        permissions: '0644'
      runcmd:
        - apt-get -y purge nano
        - apt-get -y autoremove
        - systemctl enable mount-make-rshare
        - tar -C / -zxvf /mnt/containerd/cri-containerd-cni-$CONTAINERD_VER-linux-amd64.tar.gz
        - cp /mnt/containerd/crun-$CRUN_VER-linux-amd64 /usr/local/sbin/crun
        - mkdir -p /etc/containerd
        - containerd config default | sed '/config_path/s#""#"/etc/containerd/certs.d"#' | sed '/plugins.*linux/{n;n;s#runc#crun#}' | tee /etc/containerd/config.toml
        - systemctl enable containerd
        - systemctl start containerd
        - kubeadm config images pull
        - ctr oci spec | tee /etc/containerd/cri-base.json
        - rm /etc/cni/net.d/10-containerd-net.conflist
      power_state:
        delay: "+1"
        mode: poweroff
        message: Bye Bye
        timeout: 10
        condition: True
  description: ""
  devices:
    _dev_sda1:
      path: /dev/sda1
      source: /dev/sda1
      type: unix-block
    aadisable:
      path: /sys/module/nf_conntrack/parameters/hashsize
      source: /dev/null
      type: disk
    aadisable1:
      path: /sys/module/apparmor/parameters/enabled
      source: /dev/null
      type: disk
    boot_dir:
      path: /boot
      source: /boot
      type: disk
    dev_kmsg:
      path: /dev/kmsg
      source: /dev/kmsg
      type: unix-char
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
    containerd:
      path: /mnt/containerd
      source: /home/$USER/Projects/kubernetes-env/.containerd
      type: disk
EOF

  sed "s#/dev/sda1#$(cat ~/.config/.disk)#" < /tmp/lxd-profile-k8s-cloud-init-local-registries | lxc profile edit k8s-cloud-init-local-registries
  rm /tmp/lxd-profile-k8s-cloud-init-local-registries
fi

lb=$(lxc profile ls | grep lb)
  if [ "$lb"  == "" ]; then
  lxc profile create lb

  cat <<EOF > /tmp/lxd-profile-lb
  config:
    linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay
    raw.lxc: |-
      lxc.apparmor.profile=unconfined
      lxc.cap.drop=
      lxc.cgroup.devices.allow=a
      lxc.mount.auto=proc:rw sys:rw cgroup:rw
      lxc.seccomp.profile=
    security.nesting: "true"
    security.privileged: "true"
    user.user-data: |
      #cloud-config
      apt:
        preserve_sources_list: false
        primary:
          - arches:
            - amd64
            uri: "http://archive.ubuntu.com/ubuntu/"
        security:
          - arches:
            - amd64
            uri: "http://security.ubuntu.com/ubuntu"
EOF

  PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';')
  if [ "$PROXY" != "" ]; then
    echo "        proxy: $PROXY" >> /tmp/lxd-profile-lb
  fi

  cat <<EOF >> /tmp/lxd-profile-lb
        sources:
          kubernetes.list:
            source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
            keyid: 7F92E05B31093BEF5A3C2D38FEEA9169307EA071
      packages:
        - apt-transport-https
        - ca-certificates
        - nginx
      package_update: false
      package_upgrade: false
      package_reboot_if_required: false
      locale: en_SG.UTF-8
      locale_configfile: /etc/default/locale
      timezone: Asia/Singapore
      write_files:
      - content: |
          stream {
              upstream lxd-ctrlp {
                  server lxd-ctrlp-1:6443;
                  server lxd-ctrlp-2:6443;
                  server lxd-ctrlp-3:6443;
              }
              server {
                  listen 6443;
                  proxy_pass lxd-ctrlp;
              }
          }
        path: /etc/nginx/nginx.conf
        append: true
        defer: true
      runcmd:
        - apt-get -y purge nano
        - apt-get -y autoremove
        - sleep 10
        - nginx -s reload
      default: none
  description: ""
  devices:
    _dev_sda1:
      path: /dev/sda1
      source: /dev/sda1
      type: unix-block
    aadisable:
      path: /sys/module/nf_conntrack/parameters/hashsize
      source: /dev/null
      type: disk
    aadisable1:
      path: /sys/module/apparmor/parameters/enabled
      source: /dev/null
      type: disk
    boot_dir:
      path: /boot
      source: /boot
      type: disk
    dev_kmsg:
      path: /dev/kmsg
      source: /dev/kmsg
      type: unix-char
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
EOF

  lxc profile edit lb < /tmp/lxd-profile-lb
  # cat /tmp/lxd-profile-lb | lxc profile edit lb
  rm /tmp/lxd-profile-lb
fi
MYEOF

cat <<'MYEOF' >> ~/.local/bin/prepare-lxd.sh

YY=20
CODE_NAME=focal
image=$(lxc image ls | grep focal-cloud)
if [ "$image" == "" ]; then
  if [ "$slim" == "" ]; then
    VERSION=$(curl -sSL https://cloud-images.ubuntu.com/daily/streams/v1/com.ubuntu.cloud:daily:download.json | \
              jq ".products.\"com.ubuntu.cloud.daily:server:$YY.04:amd64\".versions | keys[]" | sort -r | head -1 | tr -d '"')
    PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')
    if [ "$PROXY" != "" ]; then
      SERVER=http://$PROXY
    else
      SERVER="https://cloud-images.ubuntu.com"
    fi
    curl -SLO "$SERVER"/server/focal/"$VERSION"/focal-server-cloudimg-amd64-lxd.tar.xz
    curl -SLO "$SERVER"/server/focal/"$VERSION"/focal-server-cloudimg-amd64.squashfs
    lxc image import focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs --alias focal-cloud
    rm focal-server-cloudimg-amd64-lxd.tar.xz focal-server-cloudimg-amd64.squashfs
  else
    VERSION=$(curl -sSL https://uk.lxd.images.canonical.com/streams/v1/images.json | \
              jq ".products.\"ubuntu:$CODE_NAME:amd64:cloud\".versions | keys[]" | sort -r | head -1 | tr -d '"')
    curl -SLO https://us.lxd.images.canonical.com/images/ubuntu/focal/amd64/cloud/"$VERSION"/lxd.tar.xz
    curl -SLO https://us.lxd.images.canonical.com/images/ubuntu/focal/amd64/cloud/"$VERSION"/rootfs.squashfs
    lxc image import lxd.tar.xz rootfs.squashfs --alias focal-cloud
    rm lxd.tar.xz rootfs.squashfs
  fi
fi
MYEOF

cat <<'EOF' > ~/.bash_complete
# For kubernetes-env

if [ -x ~/.local/bin/kubectl ]
then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -F __start_kubectl k
fi

if [ -x ~/.local/bin/kind ]
then
  source <(kind completion bash)
  complete -F __start_kind kind
fi

if [ -x ~/.local/bin/kubecolor ]
then
  alias kc=kubecolor
fi

EOF

cat <<'MYEOF' > ~/.local/bin/update_kubectl.sh
#!/usr/bin/env bash

verlte() {
  [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

verlt() {
  if [ "$1" = "$2" ]; then
    return 1
  else
    verlte "$1" "$2"
  fi
}

if [ ! -x ~/.local/bin/kubectl ]; then
  echo "kubeclt not found or not executable!!"
  exit
fi

OLD_KUBECTL_VER=$(kubectl version --short --client | sed 's/.*v\(.*\)/\1/')
NEW_KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt | sed 's/.*v\(.*\)/\1/')

verlt "$OLD_KUBECTL_VER" "$NEW_KUBECTL_VER"
if [ "$?"  = 1 ]; then
  echo "No upgrade required!!"
  exit
else
  KUBECTL_VER=v"$NEW_KUBECTL_VER"
  curl -sSL -o /tmp/kubectl "https://dl.k8s.io/$KUBECTL_VER/bin/linux/amd64/kubectl"
  KUBECTL_SHA256=$(curl -sSL https://dl.k8s.io/"$KUBECTL_VER"/bin/linux/amd64/kubectl.sha256)
  OK=$(echo "$KUBECTL_SHA256" /tmp/kubectl | sha256sum --check)
  if [[ ! "$OK" =~ .*OK$ ]]; then
    echo "kubectl binary does not match sha256 checksum, aborting!!"
    rm /tmp/kubectl
    exit $?
  else
    echo "Installing kubectl verion=$KUBECTL_VER"
    mv /tmp/kubectl ~/.local/bin/kubectl
    chmod +x ~/.local/bin/kubectl
  fi
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/update_k9s.sh
#!/usr/bin/env bash

verlte() {
  [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

verlt() {
  if [ "$1" = "$2" ]; then
    return 1
  else
    verlte "$1" "$2"
  fi
}

if [ ! -x ~/.local/bin/k9s ]; then
  echo "k9s not found or not executable!!"
  exit
fi

OLD_K9S_VER=$(k9s version | grep Version | sed 's/.*v\(.*\)/\1/')
K9S_LATEST=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest)
NEW_K9S_VER=$(echo -E "$K9S_LATEST" | jq ".tag_name" | tr -d '"' | sed 's/.*v\(.*\)/\1/')

verlt "$OLD_K9S_VER" "$NEW_K9S_VER"
if [ "$?"  = 1 ]; then
  echo "No upgrade required!!"
  exit
else
  K9S_FRIEND=$(echo -E "$K9S_LATEST" | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
  curl -sSL "$K9S_FRIEND" | tar -C ~/.local/bin -zxvf - "$(basename \""$K9S_FRIEND\"" | sed 's/\(.*\)_Linux_.*/\1/')"
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/create-cluster.sh
#!/usr/bin/env bash

USER=$(whoami)

usage() {
  echo "Usage: $(basename $0) [-c] [-m] [-n <cilium|calico> [-i <ingress-ngx|nic-ap> ]]" 1>&2
  echo '       -c   "Create lxc/lxd containers only"'
  echo '       -m   "Multi-control-plane mode"'
  echo '       -n   "Install CNI. Only 2 options"'
  echo '       -i   "Install Ingress. Only 2 options. F5/NGINX Ingress Controller/AP installation not yet enabled."'
  echo
  exit 1
}

while getopts ":rlcmn:i:" o; do
    case "$o" in
        r)
            remote_registries="true"
            ;;
        l)
            local_registries="true"
            ;;
        c)
            containersonly="true"
            ;;
        m)
            multimaster="true"
            ;;
        n)
            n=$OPTARG
            if [ "$n" != "cilium" ] && [ "$n" != "calico" ]; then
                usage
            fi
            ;;
        i)
            i=$OPTARG
            if [ "$i" != "ingress-ngx" ] && [ "$n" != "nic-ap" ] || [ -z "$n" ]; then
                usage
            fi
            ;;
        *)
            usage
            ;;
    esac
done
# Ref: https://unix.stackexchange.com/questions/50563/how-can-i-detect-that-no-options-were-passed-with-getopts
shift $((OPTIND-1))

check_lxd_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep -c "$1")
    if [ "$STATUS" = "$2" ]; then
      break
    fi
    echo -en "$3"
    sleep 2
  done
  sleep 2
  echo
}

check_lb_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(lxc ls | grep lxd-lb | grep eth0)
    if [ ! "$STATUS" = "" ]; then
      break
    fi
    echo -en "\U0001F601"
    sleep 2
  done
  sleep 2
  echo
}

check_cilium_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(cilium status | grep "Cilium:" | awk '{print $4}' | sed 's/\x1b\[[0-9;]*m//g')
    if [ "$STATUS" = "OK" ]; then
      break
    fi
    echo -en "$1"
    sleep 2
  done
  sleep 4
  echo
}

check_calico_status () {
  echo -n "Wait"
  while true; do
    STATUS=$(kubectl get no | grep -c NotReady)
    if [ "$STATUS" -eq 0 ]; then
      break
    fi
    echo -en "$1"
    sleep 2
  done
  sleep 4
  echo
}

update_local_etc_hosts () {
  if [ "$multimaster" == "true" ]; then
    HOST=lxd-lb
  else
    HOST=lxd-ctrlp-1
  fi
  OUT=$(grep "$HOST" /etc/hosts)
  if [[ $OUT == "" ]]; then
    sudo sed -i "/127.0.0.1 localhost/s/localhost/localhost\n$1 $HOST/" /etc/hosts
  elif [[ "$OUT" =~ $HOST ]]; then
    sudo sed -ri "/$HOST/s/^([0-9]{1,3}\.){3}[0-9]{1,3}/$1/" /etc/hosts
  else
    echo "Error!!"
  fi
}

check_containerd_status () {
  echo -n "Wait"
  while true; do
    if [ "$multimaster" == "true" ]; then
      STATUS1=$(lxc exec lxd-ctrlp-1 -- systemctl status containerd | grep Active | grep running)
      STATUS2=$(lxc exec lxd-ctrlp-2 -- systemctl status containerd | grep Active | grep running)
      STATUS3=$(lxc exec lxd-ctrlp-3 -- systemctl status containerd | grep Active | grep running)
      if [[ "$STATUS1" =~ .*running.* ]] && [[ "$STATUS2" =~ .*running.* ]] && [[ "$STATUS3" =~ .*running.* ]]; then
        break
      fi
      echo -en "$1"
      sleep 2
    else
      STATUS=$(lxc exec lxd-ctrlp-1 -- systemctl status containerd | grep Active | grep running)
      if [[ "$STATUS" =~ .*running.* ]]; then
        break
      fi
      echo -e "$1"
      sleep 2
    fi
  done
  sleep 2
  echo
}

check_if_cluster_already_exists () {
  STATUS=$(lxc ls | grep -c "lxd-.*")
  if [ "$STATUS" -ne 0 ]; then
    echo "Old K8s Cluster exists!!"
    echo "Run 'stop-cluster.sh -d' first!!"
    exit
  fi
}

check_if_cluster_already_exists

if [ "$multimaster" == "true" ]; then
  NODESNUM=6
  CTRLP=lxd-lb
  NODES=(ctrlp-1 ctrlp-2 ctrlp-3 wrker-1 wrker-2 wrker-3)
  WRKERNODES=(1 2 3)
else
  NODESNUM=3
  CTRLP=lxd-ctrlp-1
  NODES=(ctrlp-1 wrker-1 wrker-2)
  WRKERNODES=(1 2)
fi

image=focal-cloud

if [ "$local_registries" == "true" ]; then
  if [ ! -d /home/"$USER"/Projects/kubernetes-env/.containerd ]; then
    echo "Run pull-containerd.sh first!!"
    exit 63
  fi
  registeries=$(docker container ls | grep -c registry)
  if [ "$registeries" != "4" ]; then
    echo "Are local registries running? Run create-local-registries.sh first!!"
    exit 127
  fi
  iface=$(ip link | grep ens | awk '{print $2}' | tr -d ':')
  if [ "$iface" == "" ]; then
    echo "Interface ens* no found!!"
    exit 127
  fi
  IP=$(ip a s "$iface" | head -3 | tail -1 | awk '{print $2}' | tr -d '/24$')
  count=$(lxc profile show k8s-cloud-init-local-registries | grep -c "$IP")
  if [ "$count" -eq 0 ]; then
    echo -e "lxc profile not setup for local registries!!\nExciting!!"
    exit
  fi
  profile=k8s-cloud-init-local-registries
elif [ "$remote_registries" == "true" ]; then
  if [ ! -d /home/"$USER"/Projects/kubernetes-env/.containerd ]; then
    echo "Run pull-containerd.sh first!!"
    exit 63
  fi
  PROXY=$(grep Proxy /etc/apt/apt.conf.d/* | awk '{print $2}' | tr -d ';|"' | sed 's@^http://\(.*\):3142/@\1@')
  if [ "$PROXY" == "" ]; then
    echo -e "No Remote Registries detected!!\nExciting!!"
    exit
  fi
  count=$(lxc profile show k8s-cloud-init-local-registries | grep -c "$PROXY")
  if [ "$count" -eq 1 ]; then
    echo -e "lxc profile not setup for remote registries!!\nExciting!!"
    exit
  fi
  profile=k8s-cloud-init-local-registries
else
  profile=k8s-cloud-init
fi

for c in "${NODES[@]}"; do
  lxc launch -p "$profile" "$image" lxd-"$c"
done

check_lxd_status STOP "$NODESNUM" "\U0001F600"
lxc start --all

check_lxd_status eth0 "$NODESNUM" "\U0001F604"

if [ "$multimaster" != "true" ]; then
  IPADDR=$(lxc ls | grep ctrlp | awk '{print $6}')
  update_local_etc_hosts "$IPADDR"
fi

check_containerd_status "\U0001F601"

if [ "$containersonly" == "true" ]; then
  echo "Cluster container created!!"
  exit;
fi

if [ "$multimaster" == "true" ]; then
  lxc launch -p lb focal-cloud lxd-lb
  check_lb_status
  IPADDR=$(lxc ls | grep lxd-lb | awk '{print $6}')
  update_local_etc_hosts "$IPADDR"
fi

echo
lxc exec lxd-ctrlp-1 -- kubeadm init --control-plane-endpoint "$CTRLP":6443 --upload-certs | tee kubeadm-init.out
echo
if [ ! -d ~/.kube ]; then
  mkdir ~/.kube
  ln -s ~/.kube ~/.k
fi
lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.k/config-lxd
ln -sf ~/.k/config-lxd ~/.k/config
sleep 2

if [ "$multimaster" == "true" ]; then
  for c in 2 3; do
    # shellcheck disable=SC2046 # code is irrelevant because lxc exec will not run commands in containers with quotes
    lxc exec lxd-ctrlp-"$c" -- $(tail -12 kubeadm-init.out | head -3 | tr -d '\\\n')
    sleep 2
    echo
  done
fi

for c in "${WRKERNODES[@]}"; do
  # shellcheck disable=SC2046 # code is irrelevant because lxc exec will not run commands in containers with quotes
  lxc exec lxd-wrker-"$c" -- $(tail -2 kubeadm-init.out | tr -d '\\\n')
  sleep 1
  # Ref: https://stackoverflow.com/questions/48854905/how-to-add-roles-to-nodes-in-kubernetes
  kubectl label nodes lxd-wrker-"$c" node-role.kubernetes.io/worker=
  echo
done

# Ref: https://askubuntu.com/questions/1042234/modifying-the-color-of-grep
kubectl get no -owide | GREP_COLORS="ms=1;91;107" grep --color STATUS
kubectl get no -owide | grep --color NotReady
echo
if [ -z "$n" ]; then
  echo "No CNI specified!! Doing nothing for CNI plugin!!"
  echo "You might want to deploy Calico. 'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml'"
  echo -e "Will exit here!!\ncreate-cluster.sh -h for help!!"
  exit
else
  if [ "$n" == "cilium" ]; then
    if ! command  -v cilium &> /dev/null; then
      get-cilium.sh
    fi
    cilium install
    check_cilium_status "\U0001F680"
  elif [ "$n" == "calico" ]; then
    curl -sSL https://docs.projectcalico.org/manifests/calico.yaml | sed 's#policy/v1beta1#policy/v1#' | kubectl apply -f -
    check_calico_status "\U0001F680"
  else
    echo "Error CNI flag exists but != <cilium|calico>!!"
    exit
  fi
fi
echo
# Ref: https://askubuntu.com/questions/1042234/modifying-the-color-of-grep
kubectl get no -owide | GREP_COLORS="ms=1;92;107" grep --color STATUS
kubectl get no -owide | GREP_COLORS="ms=1;92" grep --color Ready
echo
k-apply.sh
sed "/replace/s/{{ replace-me }}/10.254.254/g" < metallab-configmap.yaml.tmpl | kubectl apply -f -
if [ -z "$i" ]; then
  echo "No Ingress-Controller specified!! Doing nothing for Ingress-Controller!!"
  echo "You might want to deploy Ingress-Nginx. 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml'"
  exit
else
  if [ "$i" == "ingress-ngx" ]; then
    ingress-nginx.sh
  elif [ "$i" == "nic-ap" ]; then
    # nginx-ap-ingress.sh -p
    echo "Not implemented yet!!"
  fi
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/stop-cluster.sh
#!/usr/bin/env bash

while getopts "d" o; do
    case "$o" in
        d)
            delete="true"
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

lxc stop --all --force
if [ "$delete"  == "true" ]; then
  for c in $(lxc ls | grep lxd | awk '{print $2}'); do lxc delete "$c"; done
  rm ~/.k/{config,config-lxd} 2> /dev/null
  sudo sed -i '/lxd/d' /etc/hosts
fi
MYEOF

cat <<'MYEOF' > ~/.local/bin/record-k9s.sh
#!/usr/bin/env bash

while true;
do
  if [ -e ~/.k/config ]; then
    break;
  fi
done
k9s
MYEOF

cat <<'MYEOF' > ~/.local/bin/create-local-registries.sh
#!/usr/bin/env bash

docker run -d -p 5000:5000 \
    -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
    --restart always \
    --name registry-docker.io registry:2

docker run -d -p 5001:5000 \
    -e REGISTRY_PROXY_REMOTEURL=https://k8s.gcr.io \
    --restart always \
    --name registry-k8s.gcr.io registry:2

docker run -d -p 5002:5000 \
    -e REGISTRY_PROXY_REMOTEURL=https://quay.io \
    --restart always \
    --name registry-quay.io registry:2.5

# docker run -d -p 5003:5000 \
#     -e REGISTRY_PROXY_REMOTEURL=https://gcr.io \
#     --restart always \
#     --name registry-gcr.io registry:2

# docker run -d -p 5004:5000 \
#     -e REGISTRY_PROXY_REMOTEURL=https://ghcr.io \
#     --restart always \
#     --name registry-ghcr.io registry:

docker run -d -p 6000:5000 \
    --restart always \
    --name registry registry:2

MYEOF

cat <<'MYEOF' > ~/.local/bin/prime-local-registries.sh
#!/usr/bin/env bash

# Ref: https://stackoverflow.com/questions/1494178/how-to-define-hash-tables-in-bash
# Ref: https://stackoverflow.com/questions/12317483/array-of-arrays-in-bash
# Ref: https://stackoverflow.com/questions/31251356/how-to-get-a-list-of-images-on-docker-registry-v2
# Ref: https://devops.stackexchange.com/questions/2731/downloading-docker-images-from-docker-hub-without-using-docker
# requires bash 4 or later; on macOS, /bin/bash is version 3.x,
# so need to install bash 4 or 5 using e.g. https://brew.sh


declare -A sites
declare -a images

sites=( ["docker.io"]="10.1.1.78:5000" ["k8s.gcr.io"]="10.1.1.78:5001" ["quay.io"]="10.1.1.78:5002" )

images[0]='docker.io/calico/cni;v3.21.4'
images[1]='docker.io/calico/kube-controllers;v3.21.4'
images[2]='docker.io/calico/node;v3.21.4'
images[3]='docker.io/calico/pod2daemon-flexvol;v3.21.4'
images[4]='docker.io/library/nginx;1.21.4'
images[5]='docker.io/library/nginx;1.21.5'
images[6]='docker.io/rancher/local-path-provisioner;v0.0.21'
images[7]='k8s.gcr.io/coredns/coredns;v1.8.6'
images[8]='k8s.gcr.io/etcd;3.5.1-0'
images[9]='k8s.gcr.io/kube-apiserver;v1.23.1'
images[10]='k8s.gcr.io/kube-controller-manager;v1.23.1'
images[11]='k8s.gcr.io/kube-proxy;v1.23.1'
images[12]='k8s.gcr.io/kube-scheduler;v1.23.1'
images[13]='k8s.gcr.io/pause;3.5'
images[14]='k8s.gcr.io/pause;3.6'
images[15]='k8s.gcr.io/metrics-server/metrics-server;v0.3.7'
images[16]='quay.io/cilium/cilium;v1.11.0'
images[17]='quay.io/cilium/operator-generic;v1.11.0'
images[18]='quay.io/metallb/controller;v0.11.0'
images[19]='quay.io/metallb/speaker;v0.11.0'
images[20]='k8s.gcr.io/ingress-nginx/controller;v1.1.1'
images[21]='k8s.gcr.io/ingress-nginx/kube-webhook-certgen;v1.1.1'


for image in "${images[@]}"
do
    IFS=";" read -r -a arr <<< "$image"
    site_name="${arr[0]}"
    tag="${arr[1]}"
    site=${site_name/\/*/}
    name=${site_name/*.io\/}
    echo "site : $site"
    echo "name : $name"
    echo "tag  : $tag"
    echo
    curl -s http://"${sites[$site]}"/v2/"$name"/manifests/"$tag"?ns="$site" | jq -r '.fsLayers[].blobSum' > "${name/\//-}"-blobsums.txt
    while read -r BLOBSUM; do
      curl -s --location http://"${sites[$site]}"/v2/"$name"/blobs/"$BLOBSUM" > /dev/null
    done < "${name/\//-}"-blobsums.txt
done
rm ./*.txt

MYEOF

cat <<'MYEOF' > ~/.local/bin/delete-local-registries.sh
#!/usr/bin/env bash

registries_list=($(docker container ls | grep registry | awk '{print $13}'))

volume_list=($(for registry in "${registries_list[@]}"; do docker inspect "$registry" | jq -M '.[].Mounts | .[].Name' | tr -d '"'; done))

for registry in "${registries_list[@]}";
do
  echo -n "Stopping "
  docker stop "$registry"
  echo -n "Deleting "
  docker rm "$registry"
done

for volume in "${volume_list[@]}";
do
  echo -n "Deleting volume "
  docker volume rm "$volume"
done

MYEOF

cat <<'MYEOF' > ~/.local/bin/pull-containerd.sh
#!/usr/bin/env bash

pushd () {
    command pushd "$@" > /dev/null || exit
}

popd () {
    command popd > /dev/null || exit
}

USER=$(whoami)
pushd "$(pwd)" || exit

if [ -d "/home/$USER/Projects/kubernetes-env/.containerd" ]; then
  echo "/home/$USER/Projects/kubernetes-env/.containerd exists!! Not downloading!!"
  exit
fi

mkdir -p /home/"$USER"/Projects/kubernetes-env/.containerd
cd /home/"$USER"/Projects/kubernetes-env/.containerd || exit

CONTAINERD_LATEST=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest)
CONTAINERD_VER=$(echo -E "$CONTAINERD_LATEST" | jq -M ".tag_name" | tr -d '"' | sed 's/.*v\(.*\)/\1/')
echo "Downloading Containerd v$CONTAINERD_VER..."
echo
echo "**********************************"
echo "*                                *"
echo "* Downloading Containerd v$CONTAINERD_VER *"
echo "*                                *"
echo "**********************************"
echo
CONTAINERD_URL=$(echo -E "$CONTAINERD_LATEST" | jq -M ".assets[].browser_download_url" | grep amd64 | grep linux | grep cri | grep -v sha256 | tr -d '"')
curl -L --remote-name-all "$CONTAINERD_URL"{,.sha256sum}
sha256sum --check "$(basename "$CONTAINERD_URL")".sha256sum

CRUN_LATEST=$(curl -s https://api.github.com/repos/containers/crun/releases/latest)
CRUN_VER=$(echo -E "$CRUN_LATEST" | jq -M ".tag_name" | tr -d '"' | sed 's/.*v\(.*\)/\1/')
echo "Downloading Crun v$CRUN_VER..."
CRUN_URL=$(echo -E "$CRUN_LATEST" | jq -M ".assets[].browser_download_url" | grep amd64 | grep linux | grep -v asc | grep -v systemd | tr -d '"')
curl -L --remote-name-all "$CRUN_URL"{,.asc}

popd || exit

MYEOF

# Install kubectl
if [ ! -f ~/.local/bin/kubectl ]; then
  KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -sSL -o /tmp/kubectl "https://dl.k8s.io/$KUBECTL_VER/bin/linux/amd64/kubectl"
  KUBECTL_SHA256=$(curl -sSL https://dl.k8s.io/"$KUBECTL_VER"/bin/linux/amd64/kubectl.sha256)
  OK=$(echo "$KUBECTL_SHA256" /tmp/kubectl | sha256sum --check)
  if [[ ! "$OK" =~ .*OK$ ]]; then
    echo "kubectl binary does not match sha256 checksum, aborting!!"
    rm /tmp/kubectl
    exit $?
  else
    echo "Installing kubectl verion=$KUBECTL_VER"
    mv /tmp/kubectl ~/.local/bin/kubectl
  fi
fi

# Install kind
if [ ! -f ~/.local/bin/kind ]; then
  curl -sSL -o ~/.local/bin/kind \
    "$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq ".assets[].browser_download_url" | grep amd64 | grep linux | tr -d '"')"
fi
# Install k9s
if [ ! -f ~/.local/bin/k9s ]; then
  K9S_FRIEND=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
  curl -sSL "$K9S_FRIEND" | tar -C ~/.local/bin -zxvf - "$(basename \""$K9S_FRIEND\"" | sed 's/\(.*\)_Linux_.*/\1/')"
fi
# Install yq
if [ ! -f ~/.local/bin/yq ]; then
curl -sSL -o ~/.local/bin/yq \
  "$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq ".assets[].browser_download_url" | grep -v "tar.gz" | grep amd64 | grep linux | tr -d '"')"
fi

# Install bat
if [ ! -f ~/.local/bin/bat ]; then
  BAT=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | grep gnu | tr -d '"')
  BAT_DIR=$(basename "$BAT" | sed 's/\(^.*\).tar.gz/\1/')
  BAT_BIN=$(basename "$BAT" | sed 's/\(.*\)-v.*/\1/')
  curl -sSL "$BAT" | tar -C /tmp -zxvf -
  mv /tmp/"$BAT_DIR"/"$BAT_BIN" ~/.local/bin
  mv /tmp/"$BAT_DIR"/"$BAT_BIN".1 ~/.local/man/man1
  mv /tmp/"$BAT_DIR"/autocomplete/* ~/.local/share/completions
  rm -rf /tmp/"$BAT_DIR"
fi

# Install shellcheck
if [ ! -f ~/.local/bin/shellcheck ]; then
  SHELLCHECK=$(curl -s https://api.github.com/repos/koalaman/shellcheck/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
  SHELLCHECK_DIR=$(basename "$SHELLCHECK" | sed 's/\(^.*v.*\).linux.*/\1/')
  SHELLCHECK_BIN=$(basename "$SHELLCHECK" | sed 's/\(.*\)-v.*/\1/')
  curl -sSL "$SHELLCHECK" | tar -C /tmp --xz -xvf - "$SHELLCHECK_DIR"/"$SHELLCHECK_BIN"
  mv /tmp/"$SHELLCHECK_DIR"/"$SHELLCHECK_BIN" ~/.local/bin
  rm -rf /tmp/"$SHELLCHECK_DIR"
fi

# Install kubectx & kubens
if [ ! -f ~/.local/bin/kubectx ] || [ ! -f ~/.local/bin/kubens ]; then
  KUBE_FRIENDS=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep linux | tr -d '"')
  for friend in $KUBE_FRIENDS
  do
    curl -sSL "$friend" | tar -C ~/.local/bin -zxvf - "$(basename \""$friend\"" | sed 's/\(.*\)_v.*/\1/')"
  done
fi

# Install kubecolor
if [ ! -f ~/.local/bin/kubecolor ]; then
  KUBECOLOR=$(curl -s https://api.github.com/repos/hidetatz/kubecolor/releases/latest | jq ".assets[].browser_download_url" | grep x86_64 | grep Linux | tr -d '"')
  curl -sSL "$KUBECOLOR" | tar -C ~/.local/bin -zxvf - kubecolor
fi

chmod +x ~/.local/bin/*

lxdg=$(id | sed 's/^.*\(lxd\).*$/\1/')
dockerg=$(id | sed 's/^.*\(lxd\).*$/\1/')
if [ "$lxdg" == "" ] || [ "$dockerg" == "" ]; then
  echo -e "\n"
  echo "*************************************************************************************"
  echo "*                                                                                   *"
  echo "*  Please logout and relogin again for docker,lxd group membership to take effect.  *"
  echo "*                                                                                   *"
  echo "*************************************************************************************"
  echo -e "\n\n"
fi
