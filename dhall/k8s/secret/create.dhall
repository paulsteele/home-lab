\(values: ../common.dhall //\\ ./input.dhall) ->

let Secret = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Secret.dhall

let defaultSecret     = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Secret.dhall

let defaultMeta        = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall


in defaultSecret {
  metadata = defaultMeta {
    name = values.name
  }
} // {
  stringData = Some values.secrets
}: Secret