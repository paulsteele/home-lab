let k8s = ../dhall/dependencies/dhall-kubernetes/1.15/typesUnion.dhall

let createClusterIssuer = ../dhall/k8s/clusterIssuer/create.dhall
let createCertificate = ../dhall/k8s/certificate/create.dhall
let createSecret = ../dhall/k8s/secret/create.dhall

let issuerName    = "letsencrypt"

let customK8s = < k8s |
  ClusterIssuer : ../dhall/k8s/clusterIssuer/output.dhall
  Certificate : ../dhall/k8s/certificate/output.dhall
>

in {
  apiVersion = "v1",
  kind = "List",
  items = [
    customK8s.ClusterIssuer ( createClusterIssuer {
      name = issuerName,
      server = "https://acme-v02.api.letsencrypt.org/directory",
      email = "paul-steele@live.com",
      certmanagerSecret = "letsencrypt-cert-manager",
      accessKeyID = "AKIA5IJM3JBT4OHKN63G",
      dnsSecretName = "route53-key",
      dnsSecretKey = "key"
    }),
    customK8s.Certificate ( createCertificate {
      name = "paul-steele.com",
      namespace = "default",
      dnsNames = [
        "'*.paul-steele.com'"
      ],
      issuer = issuerName
    }),
    customK8s.Certificate ( createCertificate {
      name = "hell-yeah.org",
      namespace = "deployments",
      dnsNames = [
        "hell-yeah.org",
        "www.hell-yeah.org"
      ],
      issuer = issuerName
    }),
    customK8s.Certificate ( createCertificate {
      name = "bullmoose-party.com",
      namespace = "deployments",
      dnsNames = [
        "bullmoose-party.com",
        "www.bullmoose-party.com"
      ],
      issuer = issuerName
    }),
    customK8s.Secret ( createSecret {
      name = "route53-key",
      namespaces = ["default"],
      secrets = [
        {
          mapKey = "key",
          mapValue = ./secrets/key.txt as Text
        }
      ]
    })
  ]
}
