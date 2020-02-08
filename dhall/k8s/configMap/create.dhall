\(values: ./input.dhall) ->

let ConfigMap = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.ConfigMap.dhall

let defaultConfigMap = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ConfigMap.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall


in defaultConfigMap // {
  metadata = defaultMeta // {
    name = values.name
  }
} // {
  data = values.data
} : ConfigMap
