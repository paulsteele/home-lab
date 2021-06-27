#!/usr/bin/env bash

git clone https://github.com/prometheus-community/helm-charts.git

cd helm-charts
git checkout 14d7843fdb9db05e731c872b680cb64d3c7f25eb
cd -

kubectl apply -f helm-charts/charts/kube-prometheus-stack/crds/


rm -rf helm-charts
