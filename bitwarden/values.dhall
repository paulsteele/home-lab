let defaultCommon             = ../dhall/k8s/defaultCommon.dhall
let defaultDeployment         = ../dhall/k8s/deployment/default.dhall
let defaultContainer          = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.Container.dhall
let defaultContainerPort      = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.ContainerPort.dhall
let defaultEnvVar             = ../dhall/dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.EnvVar.dhall

let createHostVolumeMapping   = ../dhall/k8s/hostVolumeMapping/create.dhall

let mainName = "bitwarden"

let dataVolumeMapping = createHostVolumeMapping {
  name = "data",
  mountPath = "/data",
  type = "Directory",
  sourcePath = "/home/paul/bitwarden-rs/data"
}

let ingressPort = 80
let targetPort = 80

in {
  common = defaultCommon // {
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
      defaultContainer {
        name = mainName
      } // {
        image = Some "mprasil/bitwarden:latest",
        ports = Some [
          defaultContainerPort {containerPort = targetPort}
        ],
        env = Some [
            defaultEnvVar {
            name = "SIGNUPS_ALLOWED"
          } // {
            value = Some "false"
          }
        ],
        volumeMounts = Some [
          dataVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      dataVolumeMapping.volume
    ]
  }
}