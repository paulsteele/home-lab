let defaultCronJob            = ../dhall/k8s/cronJob/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createSecretEnvMapping    = ../dhall/k8s/secretEnvMapping/create.dhall

let mainName    = "mysql"
let capacity    = "8Gi"

let storageMapping = createNFSVolumeMapping {
  name = "mysqldmp",
  mountPath = "/mysqldump",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/database-backup/mysql"
}

in {
  common = {
    name = mainName
  },
  nfsPersistentVolume = {
    server = "192.168.0.105",
    path = "/srv/nfs/mysql",
    storageClassName = mainName,
    capacity = capacity
  },
  persistentVolumeClaim = {
    storageClassName = mainName,
    capacity = capacity
  },
  cronJob = defaultCronJob // {
    name = "mysqldump",
    schedule = "0 1 * * 4",
    containers = [
      defaultContainer {
        name = "mysqldump"
      } // {
        image = Some "camil/mysqldump",
        command = Some [ "/bin/bash" ],
        args = Some [
          "-c",
          "chmod +x dump.sh && ./dump.sh"
        ],
        env = Some [
            createStaticEnvMapping {
              key = "ALL_DATABASES",
              value = "true"
            },
            createStaticEnvMapping {
              key = "DB_HOST",
              value = "database-mysql"
            },
            createStaticEnvMapping {
              key = "DB_USER",
              value = "eos"
            },
            createSecretEnvMapping {
              targetKey = "DB_PASS",
              sourceKey = "mysql-password",
              sourceSecret = "database-mysql"
            }
        ],
        volumeMounts = Some [
          storageMapping.volumeMount
        ]
      }
    ],
    volumes = [
      storageMapping.volume
    ]
  },
  secret-1 = {
    name = "database-mysql",
    namespaces = ["default"]
  }
}
