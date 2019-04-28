\(values: ../common.dhall //\\ ./input.dhall) ->

let ClusterRole            = ../../dependencies/dhall-kubernetes/types/io.k8s.api.rbac.v1.ClusterRole.dhall

let defaultClusterRole     = ../../dependencies/dhall-kubernetes/default/io.k8s.api.rbac.v1.ClusterRole.dhall
let defaultPolicyRule      = ../../dependencies/dhall-kubernetes/default/io.k8s.api.rbac.v1.PolicyRule.dhall
let defaultMeta            = ../../dependencies/dhall-kubernetes/default/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

in defaultClusterRole {
  metadata = defaultMeta {
    name = values.name
  },
  rules = [ defaultPolicyRule {
    verbs = values.verbs
  } // {
    apiGroups = Some values.apiGroups,
    resources = Some values.resources
  } ]
} : ClusterRole