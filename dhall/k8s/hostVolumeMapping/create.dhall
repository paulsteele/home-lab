\(values: ./input.dhall) ->

let VolumeMount                 = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.VolumeMount.dhall
let Volume                      = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Volume.dhall

let defaultVolumeMount          = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.VolumeMount.dhall
let defaultVolume               = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.Volume.dhall
let defaultHostPathVolumeSource = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.HostPathVolumeSource.dhall

in {
  volumeMount = (defaultVolumeMount {
    name = values.name,
    mountPath = values.mountPath
  }) : VolumeMount,
  volume = (defaultVolume {
    name = values.name
  } // {
    hostPath = Some (defaultHostPathVolumeSource {
      path = values.sourcePath
    } // {
      type = Some values.type
    })
  }) : Volume
}