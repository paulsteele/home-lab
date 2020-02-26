let k8s = ../dhall/dependencies/dhall-kubernetes/1.15/typesUnion.dhall

let createNamespace = ../dhall/k8s/namespace/create.dhall

in {
  apiVersion = "v1",
  kind = "List",
  items = [
    k8s.Namespace ( createNamespace {
      name = "deployments"
    }),
    k8s.Namespace ( createNamespace {
      name = "metrics"
    })
  ]
}
