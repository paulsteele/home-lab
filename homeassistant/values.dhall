let mainName = "homeassistant"

in {
  common = {
    name = mainName
  },
  ingress = {
    hostName = "home",
    domain = "paul-steele.com"
  },
  service = {=},
  configMap = {
    data = [
      {
        mapKey = "zwave",
        mapValue = ./resources/zwave.sh as Text
      },
      {
        mapKey = "zha",
        mapValue = ./resources/zha.sh as Text
      }
    ]
  },
  deployment = {=}
}