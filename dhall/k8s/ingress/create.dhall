\(values: ../common.dhall //\\ ./input.dhall) ->

let Ingress     = ../../dependencies/dhall-kubernetes/types/io.k8s.api.extensions.v1beta1.Ingress.dhall
let IngressSpec = ../../dependencies/dhall-kubernetes/types/io.k8s.api.extensions.v1beta1.IngressSpec.dhall
let TLS         = ../../dependencies/dhall-kubernetes/types/io.k8s.api.extensions.v1beta1.IngressTLS.dhall

let defaultIngress     = ../../dependencies/dhall-kubernetes/default/io.k8s.api.extensions.v1beta1.Ingress.dhall
let defaultIngressSpec = ../../dependencies/dhall-kubernetes/default/io.k8s.api.extensions.v1beta1.IngressSpec.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall
let defaultTLS         = ../../dependencies/dhall-kubernetes/default/io.k8s.api.extensions.v1beta1.IngressTLS.dhall

let annotations = Some [
  {
    mapKey = "kubernetes.io/ingress.class",
    mapValue = "nginx"
  }
]

in defaultIngress {
  metadata = defaultMeta {
    name = values.name
  } //
  { annotations = annotations }
} //
{
  spec = defaultIngressSpec // {
    tls = defaultTLS // {
      hosts = [
        "${values.hostName}.${values.domain}"
      ]
    }
  }
}