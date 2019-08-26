\(values: ./input.dhall) ->

let VolumeMount                 = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.VolumeMount.dhall
let Volume                      = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Volume.dhall

let defaultVolumeMount          = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.VolumeMount.dhall
let defaultVolume               = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Volume.dhall
let defaultNFSVolumeSource      = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.NFSVolumeSource.dhall

in {
  volumeMount = (defaultVolumeMount {
    name = values.name,
    mountPath = values.mountPath
  }) : VolumeMount,
  volume = (defaultVolume {
    name = values.name
  } // {
    nfs = Some (defaultNFSVolumeSource {
      server = values.server,
      path = values.sourcePath
    })
  }) : Volume
}
