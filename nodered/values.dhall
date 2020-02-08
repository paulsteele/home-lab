let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createSecretEnvMapping    = ../dhall/k8s/secretEnvMapping/create.dhall
let createConfigVolumeMapping = ../dhall/k8s/configVolumeMapping/create.dhall

let mainName = "automation"

let dataVolumeMapping = createNFSVolumeMapping {
  name = "data",
  mountPath = "/data",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/automation"
}

let nodeConfigVolumeMapping = createConfigVolumeMapping {
  name = "node-config",
  configName = mainName,
  mountPath = "/nodered-config.js",
  defaultMode = 493,
  item = "node-config"
}

in {
  common = {
    name = mainName
  },
  configMap = {
    name = "automation",
    data = [
      {
        mapKey = nodeConfigVolumeMapping.volumeMount.name,
        mapValue = ./resources/nodered-config.js as Text
      }
    ]
  },
  ingress = {
    hostName = "automation",
    domain = "paul-steele.com",
    ingressPort = 1880
  },
  service = {
    ingressPort = 1880,
    targetPort = 1880
  },
  deployment = defaultDeployment // {
    containers = [
      defaultContainer // {
        name = mainName
      } // {
        image = Some "nodered/node-red:1.0.3",
        volumeMounts = [
          nodeConfigVolumeMapping.volumeMount,
          dataVolumeMapping.volumeMount
        ],
        args = [
          "--settings",
          "/nodered-config.js"
        ],
        env = [
          createStaticEnvMapping {
            key = "TZ",
            value = "America/Indiana/Indianapolis"
          }
        ]
      }
    ],
    volumes = [
      nodeConfigVolumeMapping.volume,
      dataVolumeMapping.volume
    ]
  }
}
