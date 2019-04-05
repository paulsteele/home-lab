{
  common = {
    name = "letsencrypt"
  },
  clusterIssuer = {
    server = "https://acme-v02.api.letsencrypt.org/directory",
    email = "paul-steele@live.com",
    certmanagerSecret = "letsencrypt-cert-manager",
    accessKeyID = "AKIAJNXZNXS67W52RKTA",
    dnsSecretName = "route53-key",
    dnsSecretKey = "key"
  }
}