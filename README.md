# Home-Lab Setup

Dependencies
* Helm3
* sops
* helm sops

# Cluster Setup
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
#sysctl net.bridge.bridge-nf-call-iptables=1
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/canal.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-
```
