\(values: ./input.dhall) ->

let CronJob         = ../../dependencies/dhall-kubernetes/1.15/types/io.k8s.api.batch.v1beta1.CronJob.dhall

let defaultCronJob                = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.batch.v1beta1.CronJob.dhall
let defaultCronJobSpec            = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.batch.v1beta1.CronJobSpec.dhall
let defaultMeta                   = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall
let defaultJobTemplateSpec        = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.batch.v1beta1.JobTemplateSpec.dhall
let defaultJobSpec                = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.batch.v1.JobSpec.dhall
let defaultPodTemplateSpec        = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.PodTemplateSpec.dhall
let defaultPodSpec                = ../../dependencies/dhall-kubernetes/1.15/defaults/io.k8s.api.core.v1.PodSpec.dhall


in defaultCronJob // {
  metadata = defaultMeta // {
    name = values.name
  }
} // {
  spec = Some (defaultCronJobSpec // {
    schedule = values.schedule,
    jobTemplate = defaultJobTemplateSpec // {
      metadata = defaultMeta // {
        name = values.name
      }
    } // {
      spec = Some (defaultJobSpec // {
        template = defaultPodTemplateSpec // {
          metadata = defaultMeta // {
            name = values.name
          }
        } // {
          spec = Some (defaultPodSpec // {
            containers = values.containers
          } // {
            volumes = Some values.volumes,
            restartPolicy = Some "Never"
          })
        }
      })
    }
  } // {
    successfulJobsHistoryLimit = Some 0
  })
} : CronJob
