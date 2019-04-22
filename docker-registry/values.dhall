let issuerName    = "letsencrypt"

in {
  common = {
    name = issuerName
  },
  secret-1 = {
    name = "registry.paul-steele.com",
    namespaces = ["default", "deployments"]
  }
}