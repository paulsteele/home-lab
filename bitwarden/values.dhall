let defaultCronJob            = ../dhall/k8s/cronJob/default.dhall
let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall

let mainName = "bitwarden"

let dataVolumeMapping = createNFSVolumeMapping {
  name = "data",
  mountPath = "/data",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/bitwarden"
}

let backupMapping = createNFSVolumeMapping {
  name = "backup",
  mountPath = "/backup",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/database-backup/sqlite"
}

let ingressPort = 80
let targetPort = 80

in {
  common = {
    name = mainName
  },
  ingress = {
    hostName = "passwords",
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
        image = Some "mprasil/bitwarden:latest",
        ports = [
          defaultContainerPort // {containerPort = targetPort}
        ],
        env = [
            defaultEnvVar // {
            name = "SIGNUPS_ALLOWED"
          } // {
            value = Some "false"
          }
        ],
        volumeMounts = [
          dataVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      dataVolumeMapping.volume
    ]
  },
  cronJob = defaultCronJob // {
    name = "passworddump",
    schedule = "0 1 * * 4",
    containers = [
      defaultContainer // {
        name = "passworddump"
      } // {
        image = Some "nouchka/sqlite3",
        command = [ "sqlite3" ],
        args = [
          "/data/db.sqlite3",
          ".backup '/backup/bitwarden.sq3'"
        ],
        volumeMounts = [
          dataVolumeMapping.volumeMount,
          backupMapping.volumeMount
        ]
      }
    ],
    volumes = [
      dataVolumeMapping.volume,
      backupMapping.volume
    ]
  }
}
