# Home-Lab Setup

This repository manages a Talos Linux Kubernetes cluster and its Helmfile
workloads. The node inventory and desired Talos state live in
`talos/talconfig.yaml`; `talhelper` generates the machine configs and commands.
The standard operator entrypoint is the root `Taskfile.yml`.

## Required tools

Install these on the workstation used to manage the cluster. For example:

```sh
# Task's official installer; put it somewhere on PATH.
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b "$HOME/.local/bin"
```

Then install/verify:

- [Task](https://taskfile.dev/installation/)
- [talhelper](https://budimanjojo.github.io/talhelper/latest/installation/)
- [talosctl](https://www.talos.dev/latest/introduction/quickstart/)
- [SOPS](https://github.com/getsops/sops)
- [age](https://github.com/FiloSottile/age)
- `kubectl`, Helm 3, and [Helmfile](https://helmfile.readthedocs.io/)
- `curl` and standard Linux disk tools (`lsblk`, `findmnt`, `dd`) for creating
  Talos USB boot media
- Network access from the ser2net pod to Alpine package repositories on first
  startup (the chart uses stock `alpine:3.22` and installs `ser2net` at runtime)

SOPS and age must be able to use the same age private key that decrypts this
repository's Helm secrets. The repository-root `.sops.yaml` is the only SOPS
configuration; do not create a second Talos-specific key or `.sops.yaml`.

Install the Helm plugins used by Helmfile:

```sh
helm plugin install https://github.com/jkroepke/helm-secrets
helm plugin install https://github.com/databus23/helm-diff --version master
helm plugin install https://github.com/aslafy-z/helm-git
```

## Task CLI

Run commands from the repository root. Discover the complete ordered workflow:

```sh
task --list
task --summary cluster:04-apply
task --summary helmfile:apply
```

The cluster workflow is intentionally ordered:

1. `cluster:00-installer` — generate and flash Talos boot media.
2. `cluster:01-validate` — validate `talconfig.yaml` and print the generated
   IP-to-host command inventory.
3. `cluster:02-secrets` — create encrypted Talos PKI/NUT inputs when absent.
4. `cluster:03-generate` — generate ignored per-node configs with talhelper.
5. `cluster:04-apply` — explicitly confirm and apply Talos configs.
6. `cluster:05-bootstrap` — explicitly bootstrap etcd once.
7. `cluster:06-kubeconfig` — retrieve the ignored kubeconfig.
8. `cluster:07-cilium` — install only Cilium through Helmfile.
9. `cluster:08-health` — check Talos health.
10. `cluster:09-workloads` — diff the remaining Helmfile releases.

The stages after kubeconfig are intentionally independent: running
`cluster:08-health` or `cluster:09-workloads` does not implicitly apply Cilium.
Run `cluster:07-cilium`, then health, then workloads when bootstrapping.

Run a named task directly, for example:

```sh
task cluster:01-validate
task cluster:03-generate
task cluster:04-apply CONFIRM=APPLY
# Create and flash the custom Talos boot ISO:
task cluster:00-installer
# Preselect a known USB disk (the safety checks and FLASH confirmation still run):
task cluster:00-installer DISK=/dev/sdb
# Apply one node only:
task cluster:04-apply NODE=azure CONFIRM=APPLY
```

`cluster:00-installer` generates the Image Factory ISO URL with `talhelper`,
downloads it, and offers only unmounted removable/USB disks by default. It
refuses the running system's disks, mounted disks, active swap, read-only disks,
and non-removable/non-USB disks, then requires typing `FLASH` before writing.
Use USB, PXE, or virtual media to boot each node into Talos maintenance mode;
the later `cluster:04-apply` task installs the configured Talos image to the
node's install disk.

`cluster:04-apply` defaults to insecure maintenance-mode application because it
is intended for a fresh rebuild. Review the command and type `APPLY`, or pass
`CONFIRM=APPLY` in a controlled noninteractive invocation.

## Helmfile selection and dependencies

The shared Helmfile Task runner supports all releases or one named release. If
`RELEASE` and `SKIP_DEPS` are omitted, it displays the available releases and
prompts for both choices:

```sh
task helmfile:diff
task helmfile:apply
```

Use variables for automation or an explicit selection:

```sh
task helmfile:diff RELEASE=cilium SKIP_DEPS=true
task helmfile:template RELEASE=ser2net SKIP_DEPS=true
task helmfile:build
task helmfile:apply RELEASE=ser2net SKIP_DEPS=false
```

`--skip-deps` is passed to Helmfile only when `SKIP_DEPS=true` (or when the
interactive prompt is answered yes). Apply always uses Helmfile's interactive
confirmation. Named releases also include their declared Helmfile `needs`, so
CRD providers are installed before their dependent resources. Diff validation
against live API discovery is disabled so a first-run diff can render those
resources before their CRDs exist. `cluster:07-cilium` calls this same shared
runner with `RELEASE=cilium`; it does not maintain a separate Helm installation
path.

All Kubernetes releases, including `ser2net`, must be managed through
`helmfile.yaml`. Do not use ad-hoc `helm install` or `kubectl apply` for
workloads.

Before using Kubernetes v1.35.4, read:

- `talos/helm-compatibility.md` for packages that still require upgrades or
  compatibility testing.
- `talos/workload-compatibility.md` for Talos host-device, NFS, and scheduling
  assumptions.

The cluster uses upstream Talos v1.12.7 and Kubernetes v1.35.4 because the
Intel Mac nodes cannot boot the Clang/ThinLTO EFI artifacts used by Talos v1.13+.
The Talos schematic also selects GRUB instead of the default systemd-boot UKI
handoff after the Mac's EFI rejected the v1.12.7 UKI. Do not upgrade these nodes
to Talos v1.13+ without a tested custom kernel.

Cilium remains pinned to 1.20.0 because Cilium 1.13 only supports Kubernetes
through v1.26. Cilium 1.20 requires the boolean
`kubeProxyReplacement: true`; its API service host remains the real reachable
address `192.168.0.11`.

## Desired state and secrets

- `talos/talconfig.yaml` is the central, reviewable IP-to-hostname/role/disk/
  label mapping and Talos desired state.
- `talos/talsecret.sops.yaml` contains generated Talos cluster PKI encrypted
  with the repository-root age recipient.
- `talos/talenv.sops.yaml` contains the NUT password and connection variables,
  encrypted with that same recipient. Replace the safe `CHANGE_ME` placeholder
  with `sops talos/talenv.sops.yaml` before generating configs.
- `talos/clusterconfig/` contains talhelper-generated machine configs,
  talosconfig, and kubeconfig. It is ignored and must never be committed.

To create missing encrypted inputs:

```sh
task cluster:02-secrets
```

The task encrypts from the repository root using `.sops.yaml`. To edit the NUT
input in place:

```sh
sops --config .sops.yaml talos/talenv.sops.yaml
```

## Full destructive rebuild

This procedure erases the configured node disks. Back up any data not stored on
Synology NFS first.

1. Create boot media and boot every node into Talos maintenance mode. Use the
   interactive task to download and flash the custom ISO:

   ```sh
   task cluster:00-installer
   ```

   Alternatively, use PXE or virtual media with the URL printed by
   `talhelper genurl image`. The task will not write the running system disk.
2. Verify each maintenance IP and disk:

   ```sh
   talosctl get disks --insecure --nodes <node-ip>
   ```

   Confirm the `/dev/sda` values in `talos/talconfig.yaml` before applying.
3. Ensure the NUT password is set in the encrypted environment file.
4. Validate and generate configs:

   ```sh
   task cluster:01-validate
   task cluster:03-generate
   ```

5. Apply the generated configs. The task derives every IP, hostname, role, and
   generated filename from `talconfig.yaml`:

   ```sh
   task cluster:04-apply CONFIRM=APPLY
   ```

   Apply the control plane first if performing the operation manually by node.
6. Bootstrap etcd exactly once and retrieve kubeconfig:

   ```sh
   task cluster:05-bootstrap CONFIRM=BOOTSTRAP
   task cluster:06-kubeconfig
   export KUBECONFIG="$PWD/talos/clusterconfig/kubeconfig"
   ```

7. Install Cilium, check health, then reconcile workloads:

   ```sh
   task cluster:07-cilium
   task cluster:08-health
   task cluster:09-workloads
   task helmfile:apply
   ```

The control plane remains unschedulable through Talos's
`allowSchedulingOnControlPlanes: false`; the standard
`kubernetes.io/hostname: azure` selector for the serial node is declared in the
same central file and used by the Helmfile-managed `ser2net` DaemonSet. The
live gaming placement is also preserved centrally: `blitz` (`192.168.0.12`)
receives the `gaming=true` label and `gaming=true:NoSchedule` taint used by
Pufferpanel and Argo Workflows. The existing service endpoints are used by Home
Assistant. The ser2net chart uses
stock `alpine:3.22`; its mounted startup script installs Alpine's `ser2net`
package and discovers USB devices, so no custom OCI image or Docker build is
required. A pod recreated without network access cannot reinstall the package
until repository access returns.

## Replacing a node

1. Drain or otherwise protect node-local workloads and data.
2. Boot the replacement into Talos maintenance mode and verify its disk.
3. Change only the node entry in `talos/talconfig.yaml` if the IP, hostname, or
   disk changed.
4. Regenerate and apply the selected node config:

   ```sh
   task cluster:03-generate
   task cluster:04-apply NODE=<hostname-or-ip> CONFIRM=APPLY
   ```

5. Run `task cluster:08-health`, then use the shared Helmfile diff/apply tasks
   to reconcile workloads.

## Talos upgrades

Update `talosVersion`, `kubernetesVersion`, and the schematic extension list in
`talos/talconfig.yaml`, review the Helm compatibility document, then run
`cluster:01-validate` and `cluster:03-generate`. Upgrade Talos nodes one at a
time using the generated talhelper commands. Verify Cilium, NUT graceful
shutdown, serial discovery, and workload readiness after each node.
