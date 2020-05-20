#!/usr/bin/env bash
declare -a crds=(
  "clustertasks.tekton.dev"
  "clustertriggerbindings.triggers.tekton.dev"
  "conditions.tekton.dev"
  "eventlisteners.triggers.tekton.dev"
  "extensions.dashboard.tekton.dev"
  "images.caching.internal.knative.dev"
  "pipelineresources.tekton.dev"
  "pipelineruns.tekton.dev"
  "pipelines.tekton.dev"
  "taskruns.tekton.dev"
  "tasks.tekton.dev"
  "triggerbindings.triggers.tekton.dev"
  "triggertemplates.triggers.tekton.dev"
)

declare release="ci"
declare namespace="default"

for crd in "${crds[@]}"
do
  kubectl patch crd "${crd}" --type='json' -p="[{'op': 'add', 'path': '/metadata/annotations/meta.helm.sh~1release-name', 'value':'${release}'}]"
  kubectl patch crd "${crd}" --type='json' -p="[{'op': 'add', 'path': '/metadata/annotations/meta.helm.sh~1release-namespace', 'value':'${namespace}'}]"
  kubectl patch crd "${crd}" --type='json' -p="[{'op': 'add', 'path': '/metadata/labels/app.kubernetes.io~1managed-by', 'value':'Helm'}]"
done

