let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall
let defaultEnvVarSource       = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVarSource.dhall
let defaultSecretKeySelector  = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.SecretKeySelector.dhall

let createHostVolumeMapping   = ../dhall/k8s/hostVolumeMapping/create.dhall
let createConfigVolumeMapping = ../dhall/k8s/configVolumeMapping/create.dhall

let mainName = "homeassistant"

let configVolumeMapping = createHostVolumeMapping {
  name = "config",
  mountPath = "/config",
  type = "Directory",
  sourcePath = "/home/paul/homeassistant/volumes/homeassistant"
}

let zwaveVolumeMapping = createConfigVolumeMapping {
  name = "zwave-config",
  configName = mainName,
  mountPath = "/etc/init.d/zwave",
  defaultMode = 0755,
  item = "zwave"
}

let zhaVolumeMapping = createConfigVolumeMapping {
  name = "zha-config",
  configName = mainName,
  mountPath = "/etc/init.d/zha",
  defaultMode = 0775,
  item = "zha"
}

let ingressPort = 80
let targetPort = 8123

in {
  common = {
    name = mainName
  },
  ingress = {
    hostName = "home",
    domain = "paul-steele.com",
    ingressPort = ingressPort
  },
  service = {
    ingressPort = ingressPort,
    targetPort = targetPort
  },
  configMap = {
    data = [
      {
        mapKey = zwaveVolumeMapping.volumeMount.name,
        mapValue = ./resources/zwave.sh as Text
      },
      {
        mapKey = zhaVolumeMapping.volumeMount.name,
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
          defaultContainerPort {containerPort = targetPort},
          defaultContainerPort {containerPort = 8300}
        ],
        command = Some ["sh" ],
        args = Some [
          "-c",
          "apt-get update && apt-get install socat && service zwave start && service zha start && python -m homeassistant --config /config"
        ],
        volumeMounts = Some [
          configVolumeMapping.volumeMount,
          zwaveVolumeMapping.volumeMount,
          zhaVolumeMapping.volumeMount
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
    ],
    volumes = [
      configVolumeMapping.volume,
      zwaveVolumeMapping.volume,
      zhaVolumeMapping.volume
    ]
  }
}