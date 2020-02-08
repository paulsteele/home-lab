\(values: ./input.dhall) ->

let PVC                         = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.PersistentVolumeClaim.dhall

let defaultPVC                  = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.PersistentVolumeClaim.dhall
let defaultPVCSpec              = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.PersistentVolumeClaimSpec.dhall
let defaultResourceRequirements = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ResourceRequirements.dhall
let defaultMeta                 = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

in defaultPVC // {
  metadata = defaultMeta // {
    name = values.name
  }
} // {
  spec = Some (defaultPVCSpec // {
    accessModes = [
      "ReadWriteOnce"
    ],
    storageClassName = Some values.storageClassName,
    resources = Some (defaultResourceRequirements // {
      requests = ([
        {
          mapKey = "storage",
          mapValue = values.capacity
        }
      ])
    })
  })
} : PVC
