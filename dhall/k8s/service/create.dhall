\(service : ./input.dhall) ->

{
  apiVersion = "v1",
  kind = "Service",
  metadata = {
    name = "${service.name}"
  },
  spec = {
    selector = {
      app = "${service.name}"
    },
    ports = [
      {
        protocol = "TCP",
        port = "80",
        targetPort = "8123"
      }
    ]
  }
}