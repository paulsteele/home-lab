# Home-Lab Setup

## Dependencies
* [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
* [Helm 3](https://helm.sh/)
* [sops](https://github.com/mozilla/sops)
* [helmfile](https://github.com/roboll/helmfile)

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

## Cluster Setup
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/canal.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-
```
