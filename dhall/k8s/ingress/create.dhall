\(ingress : ./input.dhall) ->

let keyValue = ../annotation/keyValue.dhall

in {
  apiVersion = "extensions/v1beta1",
  kind = "Ingress",
  metadata = {
    name = "${ingress.name}",
    annotation = [
      keyValue "kubernetes.io/ingress.class" "nginx"
    ]
  },
  spec = {
    rules = [ 
      {
        host = "${ingress.hostName}.${ingress.domain}",
        http = {
          paths = [
            {
              backend = {
                serviceName = "${ingress.name}",
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