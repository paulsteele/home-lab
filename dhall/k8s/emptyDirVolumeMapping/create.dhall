\(values: ./input.dhall) ->

let VolumeMount                  = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.VolumeMount.dhall
let Volume                       = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Volume.dhall

let defaultVolumeMount           = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.VolumeMount.dhall
let defaultVolume                = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Volume.dhall
let defaultEmptyDirVolumeSource  = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EmptyDirVolumeSource.dhall

in {
  volumeMount = (defaultVolumeMount {
    name = values.name,
    mountPath = values.mountPath
  }) : VolumeMount,
  volume = (defaultVolume {
    name = values.name
  } // {
    emptyDir = Some defaultEmptyDirVolumeSource
  }) : Volume
}
