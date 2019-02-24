{
  containers: List {
    name: Text,
    image: Text,
    ports: List {
      containerPort: Natural
    },
    command: Optional (List (Text)),
    args: List Text,
    env: Optional (List {
      name: Text,
      value: Optional Text,
      valueFrom: Optional {
        secretKeyRef: Optional {
          name: Text,
          key: Text
        }
      }
    })
  }
}