let values = ./values.dhall

let createConfigMap = ../dhall/k8s/configMap/create.dhall

let input = values.common /\ values.configMap

in createConfigMap input