# Home-Lab Setup

## Dependencies
* [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
* [Helm 3](https://helm.sh/)
* [sops](https://github.com/mozilla/sops)
* [helmfile](https://github.com/roboll/helmfile)
* [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Helm Plugins
* [helm secrets](https://github.com/zendesk/helm-secrets)
  * `helm plugin install https://github.com/futuresimple/helm-secrets`
* [helm diff](https://github.com/databus23/helm-diff)
  * `helm plugin install https://github.com/databus23/helm-diff --version master`
* [helm git](https://github.com/aslafy-z/helm-git)
  * `helm plugin install https://github.com/aslafy-z/helm-git`

## Updating Cluster
`helmfile diff` to preview changes
`helmfile apply` to apply changes

# Cluster Setup

* Install Operating System on Node
  * Holding ALT will enter boot menu for mac mini 2016s
* Deselect all desktop environments
* Select SSH tools

* (flesh out) give ansible access to node
* (flesh out) copy ssh key to node
* ```ansible-playbook 01-sudo.yaml -K```
* ```ansible-playbook 02-nodes.yaml```


## Setup Setup Kernel Modules (Per Node)
### Setup Up Modules
```
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
```
```
sudo modprobe overlay
sudo modprobe br_netfilter
```
```
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```
```
sudo sysctl --system
```
## Install Container.d
install https://github.com/containerd/containerd/releases/tag/v1.5.11

install https://github.com/containerd/containerd/blob/main/containerd.service service

```
sudo mkdir -p /etc/containerd
```
```
containerd config default | sudo tee /etc/containerd/config.toml
```
edit `/etc/containerd/config.toml`
```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
          SystemdCgroup = true
```
```
sudo systemctl restart containerd
```

### Install nfs
```
sudo apt install nfs-common
```

## Install Kuberentes (Per Node)
```
sudo apt install kubelet=1.25.3-00 kubectl=1.25.3-00 kubeadm=1.25.3-00
```

## Control Plane Node Setup
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```
```
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
### Setup Flannel
see https://github.com/flannel-io/flannel
```
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### Create Token
```
sudo kubeadm token generate
```

```
sudo kubeadm token create {token} --print-join-command
```

## Join Node to Cluster
execute the join command
