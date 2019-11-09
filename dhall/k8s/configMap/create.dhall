\(values: ../common.dhall //\\ ./input.dhall) ->

let ConfigMap = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.ConfigMap.dhall

let defaultConfigMap = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.ConfigMap.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall


in defaultConfigMap // {
  metadata = defaultMeta // {
    name = values.name
  }
} // {
  data = values.data
} : ConfigMap
