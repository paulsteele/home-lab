\(values: ./input.dhall) ->

{
  apiVersion = "certmanager.k8s.io/v1alpha1",
  kind = "ClusterIssuer",
  metadata = {
    name = values.name
  },
  spec = {
    acme = {
      server = values.server,
      email = values.email,
      privateKeySecretRef = {
        name = values.certmanagerSecret
      },
      dns01 = {
        providers = [
          {
            name = "route53",
            route53 = {
              region = "us-east-1",
              accessKeyID = values.accessKeyID,
              secretAccessKeySecretRef = {
                name = values.dnsSecretName,
                key = values.dnsSecretKey
              }
            }
          }
        ]
      }
    }
  }
} : ./output.dhall