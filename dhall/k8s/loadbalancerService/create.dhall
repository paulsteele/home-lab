\(values: ./input.dhall) ->

let singleInput = ./singleInput.dhall

let Service = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.Service.dhall
let ServicePort = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.core.v1.ServicePort.dhall
let map = ../../dependencies/dhall-lang/Prelude/List/map

let defaultService     = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Service.dhall
let defaultServiceSpec = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ServiceSpec.dhall
let defaultServicePort = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ServicePort.dhall
let defaultMeta        = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

let IntOrString        = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.apimachinery.pkg.util.intstr.IntOrString.dhall


let createPorts = \(ports: singleInput) ->
  defaultServicePort // {
    port = ports.port,
    name     = Some ports.name,
    protocol = Some "TCP",
    targetPort = Some (IntOrString.Int ports.targetPort)
  }

in defaultService // {
  metadata = defaultMeta // {
    name = "${values.name}"
  },
  spec = Some ( defaultServiceSpec // {
    selector = [
      {
        mapKey   = "app",
        mapValue = values.name
      }
    ],
    type = Some "LoadBalancer",
    ports = (map singleInput ServicePort createPorts values.ports),
    loadBalancerIP = Some values.loadBalancerIP
  })
} : Service
