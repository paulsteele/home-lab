\(values: ./input.dhall) ->

let VolumeMount                 = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.VolumeMount.dhall
let Volume                      = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.Volume.dhall

let defaultVolumeMount          = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.VolumeMount.dhall
let defaultVolume               = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Volume.dhall
let defaultHostPathVolumeSource = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.HostPathVolumeSource.dhall

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