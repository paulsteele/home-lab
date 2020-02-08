let Container = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Container.dhall
let Volume    = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Volume.dhall
in {
  name: Text,
  containers: List Container,
  volumes: List Volume,
  schedule: Text
}