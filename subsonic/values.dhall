let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall

let mainName = "subsonic"

let configVolumeMapping = createNFSVolumeMapping {
  name = "config",
  mountPath = "/subsonic",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/subsonic/config"
}

let dataVolumeMapping = createNFSVolumeMapping {
  name = "data",
  mountPath = "/data",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/subsonic/data"
}

let musicVolumeMapping = createNFSVolumeMapping {
  name = "music",
  mountPath = "/music",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/media/music"
}

let videoVolumeMapping = createNFSVolumeMapping {
  name = "video",
  mountPath = "/video",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/media/video"
}

let ingressPort = 8080
let targetPort = 8080

in {
  common = {
    name = mainName
  },
  ingress = {
    hostName = "media",
    domain = "paul-steele.com",
    ingressPort = ingressPort
  },
  service = {
    ingressPort = ingressPort,
    targetPort = targetPort
  },
  deployment = defaultDeployment // {
    containers = [
      defaultContainer {
        name = mainName
      } // {
        image = Some "mbirth/subsonic",
        ports = Some [
          defaultContainerPort {containerPort = targetPort}
        ],
        env = Some [
          createStaticEnvMapping {
            key = "TZ",
            value = "America/Indiana/Indianapolis"
          },
          createStaticEnvMapping {
            key = "LANG",
            value = "en_US.UTF-8"
          }
        ],
        volumeMounts = Some [
          configVolumeMapping.volumeMount,
          musicVolumeMapping.volumeMount,
          videoVolumeMapping.volumeMount,
          dataVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      configVolumeMapping.volume,
      musicVolumeMapping.volume,
      videoVolumeMapping.volume,
      dataVolumeMapping.volume
    ]
  }
}
