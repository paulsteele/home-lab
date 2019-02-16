\(values: ../common.dhall //\\ ./input.dhall) ->

{
  apiVersion = "v1",
  kind = "Service",
  metadata = {
    name = "${values.name}"
  },
  spec = {
    selector = {
      app = "${values.name}"
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