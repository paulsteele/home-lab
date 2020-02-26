\(values: ./input.dhall) ->

let Ingress            = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.extensions.v1beta1.Ingress.dhall

let defaultIngress     = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.extensions.v1beta1.Ingress.dhall
let defaultIngressTLS  = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.extensions.v1beta1.IngressTLS.dhall
let defaultIngressSpec = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.extensions.v1beta1.IngressSpec.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

let IntOrString        = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.apimachinery.pkg.util.intstr.IntOrString.dhall

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
    mapKey = "nginx.ingress.kubernetes.io/force-ssl-redirect",
    mapValue = "true"
  }
]

let host = "${values.hostName}.${values.domain}"

in defaultIngress // {
  metadata = defaultMeta // {
    name = values.name
  } //
  { annotations = Some (annotations) }
} //
{
  spec = Some (defaultIngressSpec // {
    tls = Some [
      defaultIngressTLS // {
        hosts = Some [
          host
        ]
      }
    ],
    rules = Some [
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
