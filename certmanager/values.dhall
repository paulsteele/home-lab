let issuerName = "letsencrypt"

in {
  common = {
    name = issuerName
  },
  clusterIssuer = [{
    server = "https://acme-v02.api.letsencrypt.org/directory",
    email = "paul-steele@live.com",
    certmanagerSecret = "letsencrypt-cert-manager",
    accessKeyID = "AKIAJNXZNXS67W52RKTA",
    dnsSecretName = "route53-key",
    dnsSecretKey = "key"
  }],
  certificate = [
    {
      certName = "paul-steele.com",
      namespace = "default",
      dnsNames = [
        "*.paul-steele.com"
      ],
      issuer = issuerName
    },
    {
      certName = "hell-yeah.org",
      namespace = "deployments",
      dnsNames = [
        "hell-yeah.org",
        "www.hell-yeah.org"
      ],
      issuer = issuerName
    },
    {
      certName = "bullmoose-party.com",
      namespace = "deployments",
      dnsNames = [
        "bullmoose-party.com",
        "www.bullmoose-party.com"
      ],
      issuer = issuerName
    }
  ]
}