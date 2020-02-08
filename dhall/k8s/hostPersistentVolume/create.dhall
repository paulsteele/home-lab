\(values: ./input.dhall) ->

let PV                          = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.PersistentVolume.dhall

let defaultPV                   = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.PersistentVolume.dhall
let defaultPVSpec               = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.PersistentVolumeSpec.dhall
let defaultHostPathVolumeSource = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.HostPathVolumeSource.dhall
let defaultMeta                 = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

in defaultPV // {
  metadata = defaultMeta // {
    name = values.name,
    labels = [
      {
        mapKey = "type",
        mapValue = "local"
      }
    ]
  }
} // {
  spec = Some (defaultPVSpec // {
    accessModes = [
      "ReadWriteOnce"
    ],
    storageClassName = Some values.storageClassName,
    capacity = [
      {
        mapKey = "storage",
        mapValue = values.capacity
      }
    ],
    hostPath = Some (defaultHostPathVolumeSource // {
      path = values.hostPath
    })
  })
}: PV
