let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createHostVolumeMapping   = ../dhall/k8s/hostVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createSecretEnvMapping    = ../dhall/k8s/secretEnvMapping/create.dhall

let mainName = "firefly"

let storageMapping = createHostVolumeMapping {
  name = "storage",
  mountPath = "/var/www/firefly-iii/storage",
  type = "Directory",
  sourcePath = "/home/paul/firefly/volumes/app"
}

let ingressPort = 80
let targetPort = 80

in {
  common = {
    name = mainName
  },
  secret-1 = {
    name = "firefly-token",
    namespaces = [ "default" ]
  },
  ingress = {
    hostName = "finance",
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
        image = Some "jc5x/firefly-iii:release-4.7.15",
        ports = Some [
          defaultContainerPort {containerPort = targetPort}
        ],
        env = Some [
            createStaticEnvMapping {
              key = "FF_DB_HOST",
              value = "database-mysql:3306"
            },
            createStaticEnvMapping {
              key = "FF_DB_USER",
              value = "eos"
            },
            createStaticEnvMapping {
              key = "FF_DB_NAME",
              value = "firefly_db"
            },
            createSecretEnvMapping {
              targetKey = "FF_DB_PASSWORD",
              sourceKey = "mysql-password",
              sourceSecret = "database-mysql"
            },
            createSecretEnvMapping {
              targetKey = "FF_APP_KEY",
              sourceKey = "FF_APP_KEY",
              sourceSecret = "firefly-token"
            },
            createStaticEnvMapping {
              key = "FF_APP_ENV",
              value = "local"
            },
            createStaticEnvMapping {
              key = "APP_URL",
              value = "https://finance.paul-steele.com"
            },
            createStaticEnvMapping {
              key = "TRUSTED_PROXIES",
              value = "**"
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