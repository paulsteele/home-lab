#!/usr/bin/env bash

git clone https://github.com/eddycharly/tekton-helm

cd tekton-helm
git checkout a6fba8e0c783c31fa92df17e3de0a6d0015a6880
cd -

kubectl apply -f tekton-helm/charts/dashboard/crds
kubectl apply -f tekton-helm/charts/pipelines/crds
kubectl apply -f tekton-helm/charts/triggers/crds

rm -rf tekton-helm
