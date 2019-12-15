\(values: ../common.dhall //\\ ./input.dhall) ->

let Ingress            = ../../dependencies/dhall-kubernetes/types/io.k8s.api.extensions.v1beta1.Ingress.dhall

let defaultIngress     = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.extensions.v1beta1.Ingress.dhall
let defaultIngressTLS  = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.extensions.v1beta1.IngressTLS.dhall
let defaultIngressSpec = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.extensions.v1beta1.IngressSpec.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

let IntOrString        = ../../dependencies/dhall-kubernetes/types/io.k8s.apimachinery.pkg.util.intstr.IntOrString.dhall

let annotations = [
  {
    mapKey = "kubernetes.io/ingress.class",
    mapValue = "nginx"
  },
  {
    mapKey = "nginx.ingress.kubernetes.io/proxy-body-size",
    mapValue = "0"
  },
  {
    mapKey = "nginx.ingress.kubernetes.io/auth-url",
    mapValue = "https://auth.paul-steele.com/api/verify"
  },
  {
    mapKey = "nginx.ingress.kubernetes.io/auth-signin",
    mapValue = "https://auth.paul-steele.com/#/"
  }
]

let host = "${values.hostName}.${values.domain}"

in defaultIngress // {
  metadata = defaultMeta // {
    name = values.name
  } //
  { annotations = annotations }
} //
{
  spec = Some (defaultIngressSpec // {
    tls = [
      defaultIngressTLS // {
        hosts = [
          host
        ]
      }
    ],
    rules = [
      {
        host = Some host,
        http = Some {
          paths = [
            {
              backend = {
                serviceName = values.name,
                servicePort = IntOrString.Int values.ingressPort
              },
              path = Some "/"
            }
          ]
        }
      }
    ]
  })
} : Ingress
