\(values: ../common.dhall //\\ ./input.dhall) ->

let keyValue = ../../dynamic/create.dhall

in {
  apiVersion = "extensions/v1beta1",
  kind = "Ingress",
  metadata = {
    name = "${values.name}",
    annotation = [
      keyValue "kubernetes.io/ingress.class" "nginx"
    ]
  },
  spec = {
    rules = [ 
      {
        host = "${values.hostName}.${values.domain}",
        http = {
          paths = [
            {
              backend = {
                serviceName = "${values.name}",
                servicePort = "80"
              },
              path = "/"
            }
          ]
        }
      }
    ]
  }
}