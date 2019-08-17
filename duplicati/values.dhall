let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createHostVolumeMapping   = ../dhall/k8s/hostVolumeMapping/create.dhall

let mainName = "duplicati"

let configVolumeMapping = createHostVolumeMapping {
  name = "config",
  mountPath = "/config",
  type = "Directory",
  sourcePath = "/home/paul/duplicati/config"
}

let sourceVolumeMapping = createHostVolumeMapping {
  name = "source",
  mountPath = "/source",
  type = "Directory",
  sourcePath = "/home/paul"
}

let port = 80
let targetPort = 8200

in {
  common = {
    name = mainName
  },
  loadbalancerService = {
    ports = [
      {
        name = mainName,
        port = port,
        targetPort = targetPort
      }
    ],
    loadBalancerIP = "192.168.0.201"
  },
  deployment = defaultDeployment // {
    containers = [
      defaultContainer {
        name = mainName
      } // {
        image = Some "linuxserver/duplicati",
        ports = Some [
          defaultContainerPort {containerPort = targetPort}
        ],
        volumeMounts = Some [
          configVolumeMapping.volumeMount,
          sourceVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      configVolumeMapping.volume,
      sourceVolumeMapping.volume
    ]
  }
}
