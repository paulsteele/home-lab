let k8s = ../dhall/dependencies/dhall-kubernetes/1.15/typesUnion.dhall
let createNFSPersistentVolume = ../dhall/k8s/nfsPersistentVolume/create.dhall
let createPersistentVolumeClaim = ../dhall/k8s/persistentVolumeClaim/create.dhall

let storageClassName = "docker-registry"

let name = "docker-registry"
let capacity = "4Gi"

in {
  apiVersion = "v1",
  kind = "List",
  items = [
    k8s.PersistentVolume ( createNFSPersistentVolume {
      name = name,
      server = "192.168.0.105",
      path = "/srv/nfs/docker-registry",
      storageClassName = storageClassName,
      capacity = capacity
    }),
    k8s.PersistentVolumeClaim ( createPersistentVolumeClaim {
      name = name,
      storageClassName = storageClassName,
      capacity = capacity
    })
  ]
}
