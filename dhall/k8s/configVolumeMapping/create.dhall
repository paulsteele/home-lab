\(values: ./input.dhall) ->

let VolumeMount                  = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.VolumeMount.dhall
let Volume                       = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.Volume.dhall

let defaultVolumeMount           = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.VolumeMount.dhall
let defaultVolume                = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Volume.dhall
let defaultConfigMapVolumeSource = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ConfigMapVolumeSource.dhall
let defaultKeyToPath             = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.KeyToPath.dhall

in {
  volumeMount = (defaultVolumeMount // {
    name = values.name,
    mountPath = values.mountPath
  } // {
    subPath = Some values.item
  }) : VolumeMount,
  volume = (defaultVolume // {
    name = values.name
  } // {
    configMap = Some (defaultConfigMapVolumeSource // {
      name = Some values.configName,
      defaultMode = Some values.defaultMode,
      items = [
        defaultKeyToPath // {
          key = values.name,
          path = values.item
        }
      ]
    })
  }) : Volume
}
