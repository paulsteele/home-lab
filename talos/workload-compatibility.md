# Workload compatibility audit for Talos

Talos removes the Debian package/service layer. Workloads that only use normal
Kubernetes networking and NFS should continue to work, but host-device and
node-placement assumptions must be explicit.

| Workload | Current assumption | Talos action |
| --- | --- | --- |
| Cilium | kube-proxy-free, hard-coded master IP | Cilium is pinned to 1.20.0, uses the real API host `192.168.0.11`, and Talhelper disables the kube-proxy manifest through the central machine patch. Cilium 1.20 requires `kubeProxyReplacement: true`, not `strict`. Test Cilium before all other workloads. |
| ser2net | Host `/dev/ttyUSB*`, host process, fixed node IP | Helmfile deploys a privileged `hostNetwork` DaemonSet with `/dev` and `/sys` mounts using stock `alpine:3.22`. A mounted startup script installs Alpine's `ser2net` package, then selects the current serial node through the standard `kubernetes.io/hostname: azure` label declared in `talconfig.yaml` and discovers USB devices by vendor/product snippets. The pod needs Alpine repository access when the package is not already present. |
| Home Assistant / Z-Wave / ZHA | `socat` creates local `/dev/ttyUSB*` PTYs and connects to the old master IP | Scripts now use `ser2net.default.svc.cluster.local` ports 3333/3334. Verify the images contain `socat`; the existing Z-Wave script uses `apk add`, which is image-specific and should be replaced with a baked image dependency if startup becomes unreliable. |
| Frigate / Coral | Host `/dev/bus/usb`, control-plane selector, USB Coral | No Frigate chart changes are included in this migration. Verify Talos USB access, the required Coral driver/extension, and pod permissions separately before moving this workload. |
| Tailscale peer relay | Host `/dev/net/tun`, `NET_ADMIN`/`NET_RAW`, host device path | Confirm `/dev/net/tun` exists on every Talos image and retain the privileged/device policy. This workload is not node-local to a named node today. |
| NFS-backed workloads | Debian `nfs-common` installed on every node | Remove the package task. Talos must be tested mounting the Synology NFS export; if mounts fail, use the supported NFS CSI driver rather than adding packages to the immutable host. |
| Pufferpanel and Argo Workflows | `gaming=true` node selector and matching taint | The live cluster places both on `blitz` (`192.168.0.12`). `talconfig.yaml` declares the label and taint, and seeds the taint through kubelet `registerWithTaints` because Kubernetes `NodeRestriction` blocks a worker kubelet from adding custom taints after registration. For an already-registered node, apply `kubectl taint node blitz gaming=true:NoSchedule --overwrite` once. Verify with `kubectl get node blitz --show-labels` and `kubectl describe node blitz` after bootstrap. |
| Generic local chart volumes | Some local chart values can use `hostPath` | Audit each rendered release with `helmfile template`; host paths must exist on the selected Talos node and be allowed by the pod security policy. |

## Required post-bootstrap checks

```sh
kubectl get nodes --show-labels
kubectl -n kube-system get pods -o wide
kubectl -n default get daemonset ser2net
kubectl -n default logs daemonset/ser2net
kubectl -n default get pods -l app.kubernetes.io/name=frigate -o wide
kubectl get events --sort-by=.lastTimestamp
```
driver rather than adding packages to the immutable host. |
For serial devices, inspect the node through the Talos API and inspect the
`ser2net` pod's generated config rather than assuming `/dev/ttyUSB0` or
`/dev/ttyUSB1`:

```sh
talosctl get links --nodes <serial-node-ip>
kubectl -n default exec daemonset/ser2net -- cat /tmp/ser2net.yaml
```

The final compatibility gate is a server-side dry run of the full Helmfile
render against Kubernetes v1.35.4, followed by a real rollout and a Talos node
reboot test for NUT graceful shutdown, USB discovery, and Cilium recovery.
