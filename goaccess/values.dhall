let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createHostVolumeMapping   = ../dhall/k8s/hostVolumeMapping/create.dhall
let createConfigVolumeMapping = ../dhall/k8s/configVolumeMapping/create.dhall

let mainName = "goaccess"

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

let nodePort = 30100
let targetPort = 7890

in {
  common = {
    name = mainName
  },
  nodeportService = {
    nodePort = nodePort,
    port = targetPort
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
          defaultContainerPort {containerPort = targetPort}
        ],
        command = Some ["goaccess"],
        args = Some [
          "-p",
          "/srv/goaccess.conf"
        ],
        volumeMounts = Some [
          logVolumeMapping.volumeMount,
          dataVolumeMapping.volumeMount,
          configVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      logVolumeMapping.volume,
      dataVolumeMapping.volume,
      configVolumeMapping.volume
    ]
  }
}
