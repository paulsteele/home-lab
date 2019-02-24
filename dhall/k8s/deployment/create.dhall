\(values: ../common.dhall //\\ ./input.dhall) ->

{
  apiVersion = "v1",
  kind = "Deployment",
  metadata = {
    name = values.name,
    labels = {
      app = values.name
    }
  },
  spec = {
    replicas = 1,
    selector = {
      matchLabels = {
        app = values.name
      }
    },
    template = {
      metadata = {
        labels = {
          app = values.name
        }
      },
      spec = {
        containers = values.containers
      }
    }
  }
}