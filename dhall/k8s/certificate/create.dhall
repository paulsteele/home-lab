\(values: ../common.dhall //\\ ./input.dhall) ->

{
  apiVersion = "certmanager.k8s.io/v1alpha1",
  kind = "Certificate",
  metadata = {
    name = values.certName,
    namespace = values.namespace
  },
  spec = {
    secretName = values.certName,
    dnsNames = values.dnsNames,
    acme = {
      config = [
        {
          dns01 = {
            provider = "route53"
          },
          domains = values.dnsNames
        }
      ]
    },
    issuerRef = {
      name = values.issuer,
      kind = "ClusterIssuer"
    }
  }
} : ./output.dhall

