\(values: ./input.dhall) ->

let defaultEnvVar             = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.EnvVar.dhall
let defaultEnvVarSource       = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.EnvVarSource.dhall
let defaultSecretKeySelector  = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.SecretKeySelector.dhall

in defaultEnvVar // {
  name = values.targetKey
} // {
  valueFrom = (defaultEnvVarSource // {
    secretKeyRef = Some (defaultSecretKeySelector // {
      key = values.sourceKey
    } // {
      name = Some values.sourceSecret
    })
  })
}
