let storageClassName = "docker-registry"

let capacity = "4Gi"

in {
  common = {
    name = "docker-registry"
  },
  nfsPersistentVolume = {
    server = "192.168.0.105",
    path = "/srv/nfs/docker-registry",
    storageClassName = storageClassName,
    capacity = capacity
  },
  persistentVolumeClaim = {
    storageClassName = storageClassName,
    capacity = capacity
  }
}
