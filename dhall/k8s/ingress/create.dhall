\(values: ../common.dhall //\\ ./input.dhall) ->

let Ingress            = ../../dependencies/dhall-kubernetes/types/io.k8s.api.extensions.v1beta1.Ingress.dhall

let defaultIngress     = ../../dependencies/dhall-kubernetes/default/io.k8s.api.extensions.v1beta1.Ingress.dhall
let defaultIngressTLS  = ../../dependencies/dhall-kubernetes/default/io.k8s.api.extensions.v1beta1.IngressTLS.dhall
let defaultIngressSpec = ../../dependencies/dhall-kubernetes/default/io.k8s.api.extensions.v1beta1.IngressSpec.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

let IntOrString        = ../../dependencies/dhall-kubernetes/types/io.k8s.apimachinery.pkg.util.intstr.IntOrString.dhall

let annotations = Some [
  {
    mapKey = "kubernetes.io/ingress.class",
    mapValue = "nginx"
  },
  { 
    mapKey = "nginx.ingress.kubernetes.io/proxy-body-size",
    mapValue = "0"
  }
]

let host = "${values.hostName}.${values.domain}"

in defaultIngress {
  metadata = defaultMeta {
    name = values.name
  } //
  { annotations = annotations }
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
