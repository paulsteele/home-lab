# Home-Lab Setup

## Dependencies
* [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
* [Helm 3](https://helm.sh/)
* [sops](https://github.com/mozilla/sops)
* [helmfile](https://github.com/roboll/helmfile)
* [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Helm Plugins
* [helm secrets](https://github.com/jkroepke/helm-secrets)
  * `helm plugin install https://github.com/jkroepke/helm-secrets`
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
  * Spam F2 will enter boot menu for nuc
* Deselect all desktop environments
* Select SSH tools

* ```ssh-copy-id -i ~/.ssh/[].pub [node-ip]```
* add node ip to inventory
* ```ansible-playbook 01-sudo.yaml -K```
* ```ansible-playbook 02-nodes.yaml```
* ```ansible-playbook 03-master.yaml```
* ```ansible-playbook 04-join-generation.yaml```
* ```ansible-playbook 05-join-execution.yaml```
