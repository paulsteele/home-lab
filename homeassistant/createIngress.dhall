let homeassistant  = {
  name = "homeassistant",
  hostName = "home",
  domain = "paul-steele.com"
} : ../dhall/k8s/ingress/input.dhall

let createIngress = ../dhall/k8s/ingress/create.dhall

in createIngress homeassistant