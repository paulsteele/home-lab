let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createHostVolumeMapping   = ../dhall/k8s/hostVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createSecretEnvMapping    = ../dhall/k8s/secretEnvMapping/create.dhall
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
  defaultMode = 0O755,
  item = "zwave"
}

let zhaVolumeMapping = createConfigVolumeMapping {
  name = "zha-config",
  configName = mainName,
  mountPath = "/etc/init.d/zha",
  defaultMode = 0O775,
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
        image = Some "homeassistant/home-assistant",
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
          createSecretEnvMapping {
            targetKey = "API_KEY",
            sourceKey = "APP_KEY",
            sourceSecret = mainName
          },
          createStaticEnvMapping {
            key = "API_URI",
            value = "http://localhost:8123/api/events/custom_scene"
          },
          createStaticEnvMapping {
            key = "MASTER_NODE",
            value = "Node009"
          }
        ],
        volumeMounts = Some [
          configVolumeMapping.volumeMount // {
            mountPath = "/home/hass/hass"
          }
        ]
      }
    ],
    volumes = [
      configVolumeMapping.volume,
      zwaveVolumeMapping.volume,
      zhaVolumeMapping.volume
    ]
  },
  secret-1 = {
    name = mainName
  }
}