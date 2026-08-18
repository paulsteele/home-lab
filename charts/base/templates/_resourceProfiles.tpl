{{- define "base.defaultResourceProfiles" -}}
tiny:
  requests:
    cpu: 25m
    memory: 64Mi
small:
  requests:
    cpu: 50m
    memory: 256Mi
medium:
  requests:
    cpu: 100m
    memory: 512Mi
large:
  requests:
    cpu: 250m
    memory: 1Gi
xlarge:
  requests:
    cpu: 500m
    memory: 2Gi
{{- end -}}

{{- define "base.resourceProfiles" -}}
{{- $profiles := include "base.defaultResourceProfiles" . | fromYaml -}}
{{- with .Values.baseResources.resourceProfiles }}
{{- $profiles = mergeOverwrite $profiles (deepCopy .) -}}
{{- end }}
{{- toYaml $profiles -}}
{{- end -}}

{{- define "base.resolveContainerResources" -}}
{{- $root := get . "root" -}}
{{- $resource := get . "resource" -}}
{{- $container := get . "container" -}}
{{- $profileName := default $resource.resourceProfile $container.resourceProfile -}}
{{- $resolved := dict -}}
{{- if $profileName -}}
  {{- $profiles := include "base.resourceProfiles" $root | fromYaml -}}
  {{- $profile := get $profiles $profileName -}}
  {{- if not $profile -}}
    {{- fail (printf "unknown resourceProfile %q for container %q" $profileName $container.name) -}}
  {{- end -}}
  {{- $resolved = deepCopy $profile -}}
{{- end -}}
{{- with $container.resources -}}
  {{- $resolved = mergeOverwrite $resolved (deepCopy .) -}}
{{- end -}}
{{- if $resolved -}}
{{ toYaml $resolved }}
{{- end -}}
{{- end -}}
