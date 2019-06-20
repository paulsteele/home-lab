\(values: ../common.dhall //\\ ./input.dhall) ->

let singleInput = ./singleInput.dhall

let Service = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.Service.dhall
let ServicePort = ../../dependencies/dhall-kubernetes/types/io.k8s.api.core.v1.ServicePort.dhall
let map = ../../dependencies/dhall-lang/Prelude/List/map

let defaultService     = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Service.dhall
let defaultServiceSpec = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ServiceSpec.dhall
let defaultServicePort = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ServicePort.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

let IntOrString        = ../../dependencies/dhall-kubernetes/types/io.k8s.apimachinery.pkg.util.intstr.IntOrString.dhall


let createPorts = \(ports: singleInput) ->
  defaultServicePort {
    port = ports.port
  } // {
    name     = Some ports.name,
    protocol = Some "TCP",
    nodePort = Some ports.nodePort
  }

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
    type = Some "NodePort",
    ports = Some (map singleInput ServicePort createPorts values.ports)
  })
} : Service
