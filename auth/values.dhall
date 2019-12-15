let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.EnvVar.dhall

let createNFSVolumeMapping    = ../dhall/k8s/nfsVolumeMapping/create.dhall
let createStaticEnvMapping    = ../dhall/k8s/staticEnvMapping/create.dhall
let createSecretEnvMapping    = ../dhall/k8s/secretEnvMapping/create.dhall
let createSecretVolumeMapping = ../dhall/k8s/secretVolumeMapping/create.dhall

let mainName = "auth"

let ingressPort = 80
let targetPort = 80

let configVolumeMapping = createSecretVolumeMapping {
  name = "config",
  secretName = mainName,
  mountPath = "/etc/authelia/config.yml",
  defaultMode = 320,
  item = "config"
}

let usersVolumeMapping = createSecretVolumeMapping {
  name = "users",
  secretName = mainName,
  mountPath = "/etc/authelia/users.yml",
  defaultMode = 320,
  item = "users"
}

in {
  common = {
    name = mainName
  },
  ingress = {
    hostName = "auth",
    domain = "paul-steele.com",
    ingressPort = 8080
  },
  service = {
    name = "auth",
    ingressPort = 8080,
    targetPort = 8080
  },
  deployment = defaultDeployment // {
    containers = [
      defaultContainer // {
        name = "auth"
      } // {
        image = Some "clems4ever/authelia:v3.16.2",
        volumeMounts = [
          configVolumeMapping.volumeMount,
          usersVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      configVolumeMapping.volume,
      usersVolumeMapping.volume
    ]
  },
  secret-1 = {
    name = mainName,
    namespaces = ["default"],
    secrets = [
      {
        mapKey = "config",
        mapValue = ./secrets/config.yaml as Text
      },
      {
        mapKey = "users",
        mapValue = ./secrets/users.yaml as Text
      }
    ]
  }
}
