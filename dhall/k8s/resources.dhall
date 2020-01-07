{
  Type = {
    ingresses: List ../dependencies/dhall-kubernetes/types/io.k8s.api.extensions.v1beta1.Ingress.dhall,
    services: List ../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Service.dhall,
    deployments: List ../dependencies/dhall-kubernetes/types/io.k8s.api.apps.v1.Deployment.dhall
  },
  default = {
    ingresses = [],
    services = [],
    deployments = []
  }
}
