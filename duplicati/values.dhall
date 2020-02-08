let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall

let mainName = "duplicati"

let configVolumeMapping = createNFSVolumeMapping {
  name = "config",
  mountPath = "/config",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/duplicati"
}

let sourceVolumeMapping = createNFSVolumeMapping {
  name = "source",
  mountPath = "/source",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs"
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
      defaultContainer // {
        name = mainName
      } // {
        image = Some "linuxserver/duplicati",
        ports = [
          defaultContainerPort // {containerPort = targetPort}
        ],
        volumeMounts = [
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
