\(values: ../common.dhall //\\ ./input.dhall) ->

let Deployment             = ../../dependencies/dhall-kubernetes/types/io.k8s.api.apps.v1.Deployment.dhall

let defaultDeployment      = ../../dependencies/dhall-kubernetes/default/io.k8s.api.apps.v1.Deployment.dhall
let defaultDeploymentSpec  = ../../dependencies/dhall-kubernetes/default/io.k8s.api.apps.v1.DeploymentSpec.dhall
let defaultSelector        = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.LabelSelector.dhall
let defaultMeta            = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall
let defaultPodTemplateSpec = ../../dependencies/dhall-kubernetes/default/io.k8s.api.core.v1.PodTemplateSpec.dhall

in defaultDeployment {
  metadata = defaultMeta {
    name = values.name
  } // {
    labels = Some [
      {
        mapKey   = "app",
        mapValue = values.name
      }
    ]
  }
} // {
  spec = Some (defaultDeploymentSpec {
    selector = defaultSelector // {
      matchLabels = Some [
        {
          mapKey = "app",
          mapValue = values.name
        }
      ]
    },
    template = defaultPodTemplateSpec {
      metadata = defaultMeta {
        name = values.name
      } // {
        labels = Some [
          {
            mapKey   = "app",
            mapValue = values.name
          }
        ]
      }
    }
  } // {
    replicas = Some 1
  })
} : Deployment