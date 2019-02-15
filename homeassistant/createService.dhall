let homeassistant  = {
  name = "homeassistant"
} : ../dhall/k8s/service/input.dhall

let createService = ../dhall/k8s/service/create.dhall

in createService homeassistant