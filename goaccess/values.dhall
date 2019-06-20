let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createHostVolumeMapping   = ../dhall/k8s/hostVolumeMapping/create.dhall
let createConfigVolumeMapping = ../dhall/k8s/configVolumeMapping/create.dhall
let createEmptyDirVolumeMapping = ../dhall/k8s/emptyDirVolumeMapping/create.dhall

let mainName = "goaccess"
let nginxName = "goaccess-nginx"

let configVolumeMapping = createConfigVolumeMapping {
  name = "config",
  configName = mainName,
  mountPath = "/srv/goaccess.conf",
  defaultMode = 0O674,
  item = "configuration"
}

let logVolumeMapping = createHostVolumeMapping {
  name = "logs",
  mountPath = "/logs",
  type = "Directory",
  sourcePath = "/home/paul/nginx/logs"
}

let dataVolumeMapping = createHostVolumeMapping {
  name = "data",
  mountPath = "/srv/data",
  type = "Directory",
  sourcePath = "/home/paul/nginx/goaccess"
}

let outputVolumeMapping = createEmptyDirVolumeMapping {
  name = "output",
  mountPath = "/usr/share/nginx/html"
}

let goaccessNodePort = 30101
let goaccessTargetPort = 7890
let nginxNodePort = 30100
let nginxTargetPort = 80

in {
  common = {
    name = mainName
  },
  nodeportService = {
    ports = [
      {
        name = mainName,
        nodePort = goaccessNodePort,
        port = goaccessTargetPort
      },
      {
        name = nginxName,
        nodePort = nginxNodePort,
        port = nginxTargetPort
      }
    ]
  },
  configMap = {
    data = [
      {
        mapKey = configVolumeMapping.volumeMount.name,
        mapValue = ./resources/goaccess.conf as Text
      }
    ]
  },
  deployment = defaultDeployment // {
    containers = [
      defaultContainer {
        name = mainName
      } // {
        image = Some "allinurl/goaccess",
        ports = Some [
          defaultContainerPort {containerPort = goaccessTargetPort}
        ],
        command = Some ["goaccess"],
        args = Some [
          "-p",
          "/srv/goaccess.conf"
        ],
        volumeMounts = Some [
          logVolumeMapping.volumeMount,
          dataVolumeMapping.volumeMount,
          configVolumeMapping.volumeMount,
          outputVolumeMapping.volumeMount
        ]
      },
      defaultContainer {
        name = nginxName
      } // {
        image = Some "nginx",
        ports = Some [
          defaultContainerPort {containerPort = nginxTargetPort}
        ],
        volumeMounts = Some [
          outputVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      logVolumeMapping.volume,
      dataVolumeMapping.volume,
      configVolumeMapping.volume,
      outputVolumeMapping.volume
    ]
  }
}
