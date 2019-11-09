\(values: ../common.dhall //\\ ./input.dhall) ->

let Deployment             = ../../dependencies/dhall-kubernetes/types/io.k8s.api.apps.v1.Deployment.dhall

let defaultDeployment      = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.apps.v1.Deployment.dhall
let defaultDeploymentSpec  = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.apps.v1.DeploymentSpec.dhall
let defaultSelector        = ../../dependencies/dhall-kubernetes/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector.dhall
let defaultMeta            = ../../dependencies/dhall-kubernetes/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall
let defaultPodTemplateSpec = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.PodTemplateSpec.dhall
let defaultPodSpec         = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.core.v1.PodSpec.dhall

let labels = [
  {
    mapKey   = "app",
    mapValue = values.name
  }
]

in defaultDeployment // {
  metadata = defaultMeta // {
    name = values.name
  } // {
    labels = labels
  }
} // {
  spec = Some (defaultDeploymentSpec // {
    selector = defaultSelector // {
      matchLabels = labels
    },
    template = defaultPodTemplateSpec // {
      metadata = defaultMeta // {
        name = values.name
      } // {
        labels = labels 
      }
    } // {
      spec = Some (defaultPodSpec // {
        containers = values.containers
      } // {
        volumes = values.volumes,
        imagePullSecrets = [
          {
            name = Some "registry.paul-steele.com"
          }
        ]
      })
    }
  } // {
    replicas = Some 1
  })
} : Deployment
