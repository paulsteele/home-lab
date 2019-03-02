let defaultDeployment        = ../dhall/k8s/deployment/default.dhall
let defaultContainer         = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort     = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar            = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall
let defaultEnvVarSource      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVarSource.dhall
let defaultSecretKeySelector = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.SecretKeySelector.dhall

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
  deployment = defaultDeployment // {
    containers = [
      defaultContainer {
        name = mainName
      } // {
        image = Some "homeassistant/homeassistant",
        ports = Some [
          defaultContainerPort {containerPort = 8123},
          defaultContainerPort {containerPort = 8300}
        ],
        command = Some ["sh" ],
        args = Some [
          "-c",
          "apt-get update && apt-get install socat && service zwave start && service zha start && python -m homeassistant --config /config"
        ]
      },
      defaultContainer {
        name = "zrc-90-listener"
      } // {
        image = Some "registry.paul-steele.com/zrc-90:latest",
        env = Some [
          defaultEnvVar {
            name = "API_KEY"
          } // {
            valueFrom = Some (defaultEnvVarSource // {
              secretKeyRef = Some (defaultSecretKeySelector {
                key = "APP_KEY"
              } // {
                name = Some "homeassistant"
              })
            })
          },
          defaultEnvVar {
            name = "API_URI"
          } // {
            value = Some "http://localhost:8123/api/events/custom_scene"
          },
          defaultEnvVar {
            name = "MASTER_NODE"
          } // {
            value = Some "Node009"
          }
        ]
      }
    ]
  }
}