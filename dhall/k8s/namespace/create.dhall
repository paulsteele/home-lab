\(values: ./input.dhall) ->

let Namespace            = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Namespace.dhall

let defaultMeta          = ../../dependencies/dhall-kubernetes/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall
let defaultNamespace     = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.Namespace.dhall


in defaultNamespace // {
  metadata = defaultMeta // {
    name = values.name
  }
} : Namespace
