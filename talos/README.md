# Talos desired state

`talconfig.yaml` is the single source of truth for this cluster. It contains
the complete IP-to-hostname/role/install-disk/label mapping and the common Talos
configuration. Do not add node-specific patch files beside it.

## Configuration layers

1. **Desired state:** `talos/talconfig.yaml` is reviewed and committed. The API
   endpoint is the real single-control-plane address:
   `https://192.168.0.11:6443`.
2. **Encrypted inputs:** `talos/talsecret.sops.yaml` contains talhelper's
   generated cluster PKI, and `talos/talenv.sops.yaml` contains the NUT values.
   Both are encrypted with the repository-root `.sops.yaml` age recipient—the
   same SOPS setup used by Helm secrets.
3. **Generated output:** `talos/clusterconfig/` contains unencrypted machine
   configs, `talosconfig`, and kubeconfig. It is ignored and disposable.

The old `talos/patches`, `talos/scripts`, and Image Factory template are gone.
Talhelper owns config generation, schematic/installer URLs, and generated
`talosctl` commands.

## Standard workflow

The root Taskfile is the operator interface:

```sh
task --list
task --summary cluster:00-validate
task cluster:00-validate
task cluster:02-generate
task cluster:03-apply CONFIRM=APPLY
task cluster:04-bootstrap CONFIRM=BOOTSTRAP
task cluster:05-kubeconfig
task cluster:06-cilium
task cluster:07-health
task cluster:08-workloads
```

`cluster:03-apply` and `cluster:04-bootstrap` require explicit confirmation.
The generated apply/bootstrap/health/kubeconfig commands come from
`talhelper gencommand`, so adding or changing a node requires only editing
`talconfig.yaml`.

## Talhelper commands

The Taskfile invokes these operations with the central file and encrypted
inputs:

```sh
talhelper validate talconfig talos/talconfig.yaml \
  --env-file talos/talenv.sops.yaml
talhelper genconfig \
  --config-file talos/talconfig.yaml \
  --env-file talos/talenv.sops.yaml \
  --secret-file talos/talsecret.sops.yaml \
  --out-dir talos/clusterconfig
talhelper gencommand apply --config-file talos/talconfig.yaml \
  --env-file talos/talenv.sops.yaml --out-dir talos/clusterconfig
talhelper gencommand bootstrap --config-file talos/talconfig.yaml \
  --env-file talos/talenv.sops.yaml --out-dir talos/clusterconfig
talhelper gencommand health --config-file talos/talconfig.yaml \
  --env-file talos/talenv.sops.yaml --out-dir talos/clusterconfig
```

Talhelper uses the node list for every generated command. It also creates the
Talos Image Factory installer URL from the `nut-client` schematic, so no
separate installer template or manually copied image URL is needed.

## Secret setup

The root SOPS configuration is intentionally the only configuration/key path.
Create missing files with:

```sh
task cluster:01-secrets
sops --config .sops.yaml talos/talenv.sops.yaml
```

The safe example has `NUT_SERVER_PASSWORD: CHANGE_ME`; replace it before
`cluster:02-generate`. Never commit decrypted secret or generated config files.

## Helmfile ordering

Cilium is installed through the shared Helmfile Task runner before the health
check. The runner supports all releases or one release and prompts for
`--skip-deps` when `SKIP_DEPS` is not supplied:

```sh
task helmfile:diff
task helmfile:diff RELEASE=cilium SKIP_DEPS=true
task helmfile:apply RELEASE=ser2net SKIP_DEPS=false
```

No workload is installed with an ad-hoc Helm or kubectl command.
