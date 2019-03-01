\(values: ../common.dhall //\\ ./input.dhall) ->

let Service = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Service.dhall

let defaultService     = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Service.dhall
let defaultServiceSpec = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ServiceSpec.dhall
let defaultServicePort = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ServicePort.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

let IntOrString        = ../../dependencies/dhall-kubernetes/types/io.k8s.apimachinery.pkg.util.intstr.IntOrString.dhall

in defaultService {
  metadata = defaultMeta {
    name = "${values.name}"
  }
} // {
  spec = Some ( defaultServiceSpec // {
    selector = Some [
      {
        mapKey   = "app",
        mapValue = values.name
      }
    ],
    ports = Some [
      defaultServicePort {
        port = 80
      } // {
        protocol = Some "TCP",
        targetPort = Some (IntOrString.Int 8123)
      }
    ]
  })
} : Service