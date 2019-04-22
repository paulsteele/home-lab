let storageClassName = "docker-registry"

let capacity = "4Gi"

in {
  common = {
    name = "docker-registry"
  },
  hostPersistentVolume = {
    hostPath = "/home/paul/docker-registry",
    storageClassName = storageClassName,
    capacity = capacity
  },
  persistentVolumeClaim = {
    storageClassName = storageClassName,
    capacity = capacity
  },
  secret-1 = {
    name = "registry.paul-steele.com",
    namespaces = ["default", "deployments"]
  }
}