let values = ./values.dhall

let createDeployment = ../dhall/k8s/deployment/create.dhall

let input = values.common /\ values.deployment

in createDeployment input