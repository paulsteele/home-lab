{
  common = {
    name = "discord-bot-config"
  },
  secret-1 = {
    namespaces = ["deployments"],
    secrets = [
      {
        mapKey = "config.json",
        mapValue = ./secrets/config.json as Text
      }
    ]
  }
}
