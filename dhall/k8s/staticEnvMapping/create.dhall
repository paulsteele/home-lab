\(values: ./input.dhall) ->

let defaultEnvVar             = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.EnvVar.dhall

in defaultEnvVar // {
  name = values.key
} // {
  value = Some values.value
}
