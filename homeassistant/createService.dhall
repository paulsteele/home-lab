let values = ./values.dhall

let createService = ../dhall/k8s/service/create.dhall

let input = values.common /\ values.service

in createService input