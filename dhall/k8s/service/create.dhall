\(values: ./input.dhall) ->

let Service = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.Service.dhall

let defaultService     = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Service.dhall
let defaultServiceSpec = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ServiceSpec.dhall
let defaultServicePort = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ServicePort.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

let IntOrString        = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.apimachinery.pkg.util.intstr.IntOrString.dhall

in defaultService // {
  metadata = defaultMeta // {
    name = "${values.name}"
  }
} // {
  spec = Some ( defaultServiceSpec // {
    selector = [
      {
        mapKey   = "app",
        mapValue = values.name
      }
    ],
    ports = [
      defaultServicePort // {
        port = values.ingressPort
      } // {
        protocol = Some "TCP",
        targetPort = Some (IntOrString.Int values.targetPort)
      }
    ]
  })
} : Service
