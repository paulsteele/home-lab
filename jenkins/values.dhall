let storageClassName = "jenkins"

let capacity = "8Gi"

let deploymentPermissionName = "deployments"
let ciPermissionName         = "ci-jenkins"

in {
  common = {
    name = "jenkins"
  },
  nfsPersistentVolume = {
    server = "192.168.0.105",
    path = "/srv/nfs/jenkins",
    storageClassName = storageClassName,
    capacity = capacity
  },
  persistentVolumeClaim = {
    storageClassName = storageClassName,
    capacity = capacity
  },
  serviceAccount-1 = {
    name = deploymentPermissionName,
    automountServiceAccountToken = True
  },
  serviceAccount-2 = {
    name = ciPermissionName,
    automountServiceAccountToken = False
  },
  clusterRole-1 = {
    name = deploymentPermissionName,
    apiGroups = [
      "apps",
      "extensions",
      ""
    ],
    resources = [
      "pods",
      "services",
      "deployments",
      "ingresses",
      "configmaps"
    ],
    verbs = [
      "'*'"
    ]
  },
  clusterRole-2 = {
    name = ciPermissionName,
    apiGroups = [
      ""
    ],
    resources = [
      "'*'"
    ],
    verbs = [
      "'*'"
    ]
  },
  clusterRoleBinding-1 = {
    name = deploymentPermissionName,
    namespace = "deployments"
  },
  clusterRoleBinding-2 = {
    name = ciPermissionName,
    namespace = "default"
  }
}
