let k8s = ../dhall/dependencies/dhall-kubernetes/1.15/typesUnion.dhall
let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createSecretEnvMapping    = ../dhall/k8s/secretEnvMapping/create.dhall
let createIngress = ../dhall/k8s/ingress/create.dhall
let createService = ../dhall/k8s/service/create.dhall
let createDeployment = ../dhall/k8s/deployment/create.dhall
let createSecret = ../dhall/k8s/secret/create.dhall

let mainName = "firefly"

let storageMapping = createNFSVolumeMapping {
  name = "storage",
  mountPath = "/var/www/firefly-iii/storage",
  server = "192.168.0.105",
  sourcePath = "/srv/nfs/firefly"
}

let ingressPort = 80
let targetPort = 80

in {
  apiVersion = "v1",
  kind = "List",
  items = [
    k8s.Ingress( createIngress {
      name = mainName,
      hostName = "finance",
      domain = "paul-steele.com",
      ingressPort = ingressPort
    }),
    k8s.Service( createService {
      name = "firefly",
      ingressPort = ingressPort,
      targetPort = targetPort
    }),
    k8s.Deployment( createDeployment ( defaultDeployment // {
      name = mainName,
      containers = [
        defaultContainer // {
          name = mainName,
          image = Some "jc5x/firefly-iii:release-5.0.4",
          ports = Some [
            defaultContainerPort // {containerPort = targetPort}
          ],
          env = Some [
              createStaticEnvMapping {
                key = "DB_HOST",
                value = "database-mysql"
              },
              createStaticEnvMapping {
                key = "DB_USERNAME",
                value = "eos"
              },
              createStaticEnvMapping {
                key = "DB_PORT",
                value = "3306"
              },
              createStaticEnvMapping {
                key = "DB_CONNECTION",
                value = "mysql"
              },
              createStaticEnvMapping {
                key = "DB_DATABASE",
                value = "firefly_db"
              },
              createSecretEnvMapping {
                targetKey = "DB_PASSWORD",
                sourceKey = "mysql-password",
                sourceSecret = "database-mysql"
              },
              createSecretEnvMapping {
                targetKey = "APP_KEY",
                sourceKey = "FF_APP_KEY",
                sourceSecret = "firefly-token"
              },
              createStaticEnvMapping {
                key = "APP_ENV",
                value = "local"
              },
              createStaticEnvMapping {
                key = "APP_URL",
                value = "https://finance.paul-steele.com"
              },
              createStaticEnvMapping {
                key = "TRUSTED_PROXIES",
                value = "'**'"
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
    })),
    k8s.Secret( createSecret {
      name = "firefly-token",
      namespaces = [ "default" ],
      secrets = [
        {
          mapKey = "FF_APP_KEY",
          mapValue = "./secrets/ff_app_key.txt"
        }
      ]
    })
  ]
}
