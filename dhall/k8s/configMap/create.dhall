\(values: ../common.dhall //\\ ./input.dhall) ->

{
  apiVersion = "v1",
  kind = "ConfigMap",
  metadata = {
    name = values.name
  },
  data = values.data
}