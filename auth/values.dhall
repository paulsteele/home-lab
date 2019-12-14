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

let cliVolumeMapping = createSecretVolumeMapping {
  name = "cli",
  secretName = mainName,
  mountPath = "/opt/jboss/startup-scripts/jboss.cli",
  defaultMode = 493,
  item = "cli"
}

let policyVolumeMapping = createSecretVolumeMapping {
  name = "policy",
  secretName = mainName,
  mountPath = "/pomerium/config.yaml",
  defaultMode = 320,
  item = "policy"
}

let certVolumeMapping = createSecretVolumeMapping {
  name = "cert",
  secretName = mainName,
  mountPath = "/certs/pomerium.cert",
  defaultMode = 320,
  item = "cert"
}

let keyVolumeMapping = createSecretVolumeMapping {
  name = "certkey",
  secretName = mainName,
  mountPath = "/certs/pomerium.key",
  defaultMode = 320,
  item = "certkey"
}

in {
  common = {
    name = mainName
  },
  ingress-keycloak = {
    name = "keycloak",
    serviceName = "keycloak",
    hostName = "keycloak",
    domain = "paul-steele.com",
    ingressPort = 8080
  },
  service-keycloak = {
    name = "keycloak",
    ingressPort = 8080,
    targetPort = 8080
  },
  deployment-keycloak = defaultDeployment // {
    name = "keycloak",
    containers = [
      defaultContainer // {
        name = "keycloak"
      } // {
        image = Some "jboss/keycloak:8.0.1",
        env = [
          createStaticEnvMapping {
            key = "PROXY_ADDRESS_FORWARDING",
            value = "true"
          },
          createStaticEnvMapping {
            key = "KEYCLOAK_USER",
            value = "paul"
          },
          createStaticEnvMapping {
            key = "DB_ADDR",
            value = "database-mysql"
          },
          createStaticEnvMapping {
            key = "DB_PORT",
            value = "3306"
          },
          createStaticEnvMapping {
            key = "DB_VENDOR",
            value = "h2"
          },
          createStaticEnvMapping {
            key = "DB_USER",
            value = "eos"
          },
          createStaticEnvMapping {
            key = "JDBC_PARAMS",
            value = "useSSL=false"
          },
          createSecretEnvMapping {
            targetKey = "DB_PASSWORD",
            sourceKey = "mysql-password",
            sourceSecret = "database-mysql"
          },
          createSecretEnvMapping {
            targetKey = "KEYCLOAK_PASSWORD",
            sourceKey = "keycloak_admin",
            sourceSecret = mainName
          }
        ],
        volumeMounts = [
          cliVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      cliVolumeMapping.volume
    ]
  },
  deployment-pomerium = defaultDeployment // {
    name = "pomerium",
    containers = [
      defaultContainer // {
        name = "pomerium"
      } // {
        image = Some "pomerium/pomerium:v0.5.2",
        env = [
          createStaticEnvMapping {
            key = "ADMINISTRATORS",
            value = "paul_steele@live.com"
          },
          createStaticEnvMapping {
            key = "FORWARD_AUTH_URL",
            value = "https://fwd.paul-steele.com"
          },
          createStaticEnvMapping {
            key = "AUTHENTICATE_SERVICE_URL",
            value = "https://auth.paul-steele.com"
          },
          createStaticEnvMapping {
            key = "ADDRESS",
            value = ":8080"
          },
          createStaticEnvMapping {
            key = "IDP_CLIENT_ID",
            value = "test-account"
          },
          createStaticEnvMapping {
            key = "IDP_PROVIDER",
            value = "oidc"
          },
          createStaticEnvMapping {
            key = "CERTIFICATE_FILE",
            value = "/certs/pomerium.cert"
          },
          createStaticEnvMapping {
            key = "CERTIFICATE_KEY_FILE",
            value = "/certs/pomerium.key"
          },
          createStaticEnvMapping {
            key = "IDP_PROVIDER_URL",
            value = "https://keycloak.paul-steele.com/auth/realms/master"
          },
          createSecretEnvMapping {
            targetKey = "SHARED_SECRET",
            sourceKey = "shared_secret",
            sourceSecret = mainName
          },
          createSecretEnvMapping {
            targetKey = "COOKIE_SECRET",
            sourceKey = "cookie_secret",
            sourceSecret = mainName
          },
          createSecretEnvMapping {
            targetKey = "IDP_CLIENT_SECRET",
            sourceKey = "client-secret",
            sourceSecret = mainName
          }
        ],
        volumeMounts = [
          policyVolumeMapping.volumeMount,
          certVolumeMapping.volumeMount,
          keyVolumeMapping.volumeMount
        ]
      }
    ],
    volumes = [
      policyVolumeMapping.volume,
      certVolumeMapping.volume,
      keyVolumeMapping.volume
    ]
  },
  ingress-fwd = {
    name = "pomerium-fwd",
    serviceName = "pomerium",
    hostName = "fwd",
    domain = "paul-steele.com",
    ingressPort = 8080
  },
  ingress-auth = {
    name = "pomerium-auth",
    serviceName = "pomerium",
    hostName = "auth",
    domain = "paul-steele.com",
    ingressPort = 8080
  },
  service-pomerium = {
    name = "pomerium",
    ingressPort = 8080,
    targetPort = 8080
  },
  secret-1 = {
    name = mainName,
    namespaces = ["default"],
    secrets = [
      {
        mapKey = "keycloak_admin",
        mapValue = ./secrets/keycloak_admin.txt as Text
      },
      {
        mapKey = "shared_secret",
        mapValue = ./secrets/shared_secret.txt as Text
      },
      {
        mapKey = "cookie_secret",
        mapValue = ./secrets/cookie_secret.txt as Text
      },
      {
        mapKey = "cli",
        mapValue = ./resources/datasource.cli as Text
      },
      {
        mapKey = "client-secret",
        mapValue = ./secrets/client_secret.txt as Text
      },
      {
        mapKey = "policy",
        mapValue = ./resources/policy.yaml as Text
      },
      {
        mapKey = "cert",
        mapValue = ./secrets/pomerium.cert as Text
      },
      {
        mapKey = "certkey",
        mapValue = ./secrets/pomerium.key as Text
      }
    ]
  }
}
