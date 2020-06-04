#!/usr/bin/env bash

git clone https://github.com/eddycharly/tekton-helm

cd tekton-helm
git checkout b4f130eba03a3126b55c7b615dbc77f1ac347169
cd -

kubectl apply -f tekton-helm/charts/dashboard/crds
kubectl apply -f tekton-helm/charts/pipelines/crds
kubectl apply -f tekton-helm/charts/triggers/crds

rm -rf tekton-helm
