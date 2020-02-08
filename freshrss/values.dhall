let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ContainerPort.dhall

let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall

let mainName = "freshrss"

let configVolumeMapping = createNFSVolumeMapping {
  name = "config",
  mountPath = "/config",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/freshrss/config"
}

let ingressPort = 80
let targetPort = 80

in {
  common = {
    name = mainName
  },
  ingress = {
    hostName = "reader",
    domain = "paul-steele.com",
    ingressPort = ingressPort
  },
  service = {
    ingressPort = ingressPort,
    targetPort = targetPort
  },
  deployment = defaultDeployment // {
    containers = [
      defaultContainer // {
        name = mainName
      } // {
        image = Some "linuxserver/freshrss",
        ports = [
          defaultContainerPort // {containerPort = targetPort}
        ],
        env = [
          createStaticEnvMapping {
            key = "CRON_MIN",
            value = "5, 35"
          }
        ],
        volumeMounts = [
          configVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      configVolumeMapping.volume
    ]
  }
}
