\(values: ../common.dhall //\\ ./input.dhall) ->

let Namespace            = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Namespace.dhall

let defaultMeta          = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall
let defaultNamespace     = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Namespace.dhall


in defaultNamespace {
  metadata = defaultMeta {
    name = values.name
  }
} : Namespace
