{
  apiVersion: Text,
  kind: Text,
  metadata: {
    name: Text
  },
  spec: {
    acme: {
      server: Text,
      email: Text,
      privateKeySecretRef: {
        name: Text
      },
      dns01:{
        providers: List({
          name: Text,
          route53: {
            region: Text,
            accessKeyID: Text,
            secretAccessKeySecretRef: {
              name: Text,
              key: Text
            }
          }
        })
      }
    }
  }
}