{
  apiVersion: Text,
  kind: Text,
  metadata: {
    name: Text,
    namespace: Text
  },
  spec: {
    secretName: Text,
    dnsNames: List(Text),
    acme: {
      config: List({
        dns01: {
          provider: Text
        },
        domains: List(Text)
      })
    },
    issuerRef: {
      name: Text,
      kind: Text
    }
  }
}