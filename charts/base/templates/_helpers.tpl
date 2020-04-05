{{- define "base.name" -}}
{{- .Release.Name | printf "%s-%s" .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "base.metadata" -}}
metadata:
  name: {{ include "base.name" . }}
  labels:
    app: {{ include "base.name" . }}
{{- end -}}
