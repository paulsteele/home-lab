\(values: ./input.dhall) ->

let ServiceAccount = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.ServiceAccount.dhall

let defaultServiceAccount = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.ServiceAccount.dhall
let defaultMeta           = ../../dependencies/dhall-kubernetes/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

in defaultServiceAccount // {
  metadata = defaultMeta // {
    name = values.name
  } // {
    namespace = Some "default"
  }
} // {
  automountServiceAccountToken = Some values.automountServiceAccountToken
} : ServiceAccount
