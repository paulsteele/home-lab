\(values: ../common.dhall //\\ ./input.dhall) ->

let PV                          = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.PersistentVolume.dhall

let defaultPV                   = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.PersistentVolume.dhall
let defaultPVSpec               = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.PersistentVolumeSpec.dhall
let defaultNFSVolumeSource      = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.NFSVolumeSource.dhall
let defaultMeta                 = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

in defaultPV {
  metadata = defaultMeta {
    name = values.name
  } // {
    labels = Some [
      {
        mapKey = "type",
        mapValue = "local"
      }
    ]
  }
} // {
  spec = Some (defaultPVSpec // {
    accessModes = Some [
      "ReadWriteOnce"
    ],
    storageClassName = Some values.storageClassName,
    capacity = Some [
      {
        mapKey = "storage",
        mapValue = values.capacity
      }
    ],
    nfs = Some (defaultHostPathVolumeSource {
      server = values.server,
      path = values.path
    })
  })
}: PV
