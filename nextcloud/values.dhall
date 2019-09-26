let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createSecretEnvMapping    = ../dhall/k8s/secretEnvMapping/create.dhall

let mainName = "nextcloud"

let storageMapping = createNFSVolumeMapping {
  name = "storage",
  mountPath = "/var/www/html",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/nextcloud"
}

let ingressPort = 80
let targetPort = 80

in {
  common = {
    name = mainName
  },
  secret-1 = {
    name = "nextcloud-admin-pass",
    namespaces = [ "default" ]
  },
  ingress = {
    hostName = "files",
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
        image = Some "nextcloud:17-rc",
        ports = Some [
          defaultContainerPort {containerPort = targetPort}
        ],
        env = Some [
            createStaticEnvMapping {
              key = "MYSQL_HOST",
              value = "database-mysql:3306"
            },
            createStaticEnvMapping {
              key = "MYSQL_USER",
              value = "eos"
            },
            createStaticEnvMapping {
              key = "MYSQL_DATABASE",
              value = "nextcloud"
            },
            createSecretEnvMapping {
              targetKey = "MYSQL_PASSWORD",
              sourceKey = "mysql-password",
              sourceSecret = "database-mysql"
            },
            createSecretEnvMapping {
              targetKey = "NEXTCLOUD_ADMIN_PASSWORD",
              sourceKey = "NEXTCLOUD_ADMIN_PASSWORD",
              sourceSecret = "nextcloud-admin-pass"
            },
            createStaticEnvMapping {
              key = "NEXTCLOUD_ADMIN_USER",
              value = "paul"
            },
            createStaticEnvMapping {
              key = "NEXTCLOUD_TRUSTED_DOMAINS",
              value = "files.paul-steele.com"
            },
            createStaticEnvMapping {
              key = "NEXCLOUD_UPDATE",
              value = "1"
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
  }
}
