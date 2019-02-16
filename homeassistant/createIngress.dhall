let values = ./values.dhall

let createIngress = ../dhall/k8s/ingress/create.dhall

let input = values.common /\ values.ingress

in createIngress input