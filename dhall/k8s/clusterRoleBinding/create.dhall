\(values: ./input.dhall) ->

let RoleBinding            = ../../dependencies/dhall-kubernetes/types/io.k8s.api.rbac.v1.RoleBinding.dhall

let defaultRoleBinding     = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.rbac.v1.RoleBinding.dhall
let defaultRoleRef         = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.rbac.v1.RoleRef.dhall
let defaultSubject         = ../../dependencies/dhall-kubernetes/defaults/io.k8s.api.rbac.v1.Subject.dhall

let defaultMeta            = ../../dependencies/dhall-kubernetes/defaults/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta.dhall

in defaultRoleBinding // {
  metadata = defaultMeta // {
    name = values.name
  } // {
    namespace = Some values.namespace
  },
  roleRef = defaultRoleRef // {
    apiGroup = "rbac.authorization.k8s.io",
    kind = "ClusterRole",
    name = values.name
  }
} // {
  subjects = ([
    defaultSubject // {
      kind = "ServiceAccount",
      name = values.name
    } // {
      namespace = Some "default"
    }
  ])
} : RoleBinding
