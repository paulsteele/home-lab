# Helm compatibility gate for Kubernetes v1.35.4

Talos is pinned to upstream v1.12.7 and the generated cluster is pinned to
Kubernetes v1.35.4. This supported upstream line is selected for the Intel Mac
nodes, whose Apple EFI firmware cannot boot the Clang/ThinLTO artifacts used by
Talos v1.13+.

Run `helmfile diff` and render every release against a v1.35.4 API server before
rebuilding production nodes.

## Required or high-risk updates

| Release/dependency | Version before this migration | Version observed/selected in the configured repo | Action |
| --- | ---: | ---: | --- |
| Cilium | 1.13.0 | 1.20.0 | **Updated in this change.** Cilium 1.13 only guarantees Kubernetes through v1.26; keep `kubeProxyReplacement: true`, `k8sServiceHost: 192.168.0.11`, and Talhelper's `cluster.proxy.disabled: true` together. |
| MetalLB | 0.13.9 | 0.16.1 | **Update and test before rollout.** Reconcile CRDs and verify the existing `IPAddressPool`/`L2Advertisement` objects. |
| Argo Workflows | 0.20.5 | 1.0.23 | **Major update required.** Review CRDs, RBAC, workflow fields, and the local `argo`/`argo-workflows` templates. |
| cert-manager | v1.20.1 | v1.21.1 | **Still requires review.** It was intentionally not changed in this migration; its existing Chart.lock is also out of sync with Chart.yaml, so reconcile/test the dependency before relying on Kubernetes v1.35.4. |
| NFS subdir provisioner | 4.0.11 | 4.0.18 | Update at minimum; evaluate moving to the maintained NFS CSI driver instead of depending on the legacy provisioner. Talos supplies the NFS client in the kernel, so no Debian `nfs-common` task is needed. |

## Strongly recommended refreshes

These are not Talos-specific blockers, but their checked-in versions are stale
relative to the configured repositories and should be refreshed through their
local chart dependencies and locks, then rendered against Kubernetes v1.35.4:

- ExternalDNS `1.20.0` -> `1.21.1`.
- Traefik `39.0.7` -> `41.1.1`.
- Tailscale operator `1.96.5` -> `1.98.9`.
- Cloudflare tunnel ingress controller `0.0.9` -> `0.0.24`; it was intentionally not changed here. Review its values/API behavior before the Kubernetes v1.35.4 rollout.
- Docker registry `2.2.2` -> `3.0.0` (review chart breaking changes).
- Keycloak `18.2.1` is an old legacy Codecentric chart; do not treat a minor chart bump as a compatibility solution. Plan a migration to a maintained Keycloak chart/operator and test the existing secrets and ingress.
- Frigate dependency `7.8.0` should be revalidated against the desired Frigate image and Coral USB access; the chart metadata and configured image are already out of alignment.

The local application charts are not automatically compatible merely because
they render as Helm v2 charts. Audit their generated resources and custom
resources, especially:

- The optional `extensions/v1beta1` branch in `charts/base/templates/_ingress.yaml`
  is not valid on current Kubernetes versions; update that chart separately if any release
  uses `baseResources.ingresses`.
- Review Tekton `v1beta1` resources in `charts/base/templates/_clusterTasks.yaml`
  and `_clusterTriggerBindings.yaml` against the installed Tekton CRDs.
- Verify all cert-manager, MetalLB, Tailscale, Argo, and external-dns CRDs are
  installed at the versions expected by their charts.

## Repeatable checks

From the repository root, after updating dependencies through Helmfile-managed
local charts. Until the intentionally untouched legacy locks are reconciled,
use `--skip-deps` only for rendering already-present local dependency archives;
normal dependency builds will correctly fail on the stale cert-manager/other
flagged packages:

```sh
helmfile build
helm lint charts/ser2net charts/cilium charts/frigate
helmfile template > /tmp/home-lab-rendered.yaml
kubectl apply --dry-run=server -f /tmp/home-lab-rendered.yaml
helmfile diff
```

The last two commands require a live v1.35.4 cluster. Do not bypass Helmfile
with ad-hoc `helm install` or `kubectl apply` for releases.
