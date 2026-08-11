{{- define "base.name" -}}
{{- default (.Release.Name | printf "%s-%s" .Chart.Name | trunc 63 | trimSuffix "-") .Values.baseResources.name -}}
{{- end -}}

{{- define "base.labels" -}}
{{- if .Values.baseResources.recommendedLabels }}
{{ include "base.recommendedLabels" . }}
{{- else }}
{{- if or (not (hasKey .Values.baseResources "useAppLabel")) .Values.baseResources.useAppLabel }}
app: {{ include "base.name" . }}
{{- end }}
{{- with .Values.baseResources.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "base.recommendedLabels" -}}
app.kubernetes.io/name: {{ include "base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "base.recommendedSelectorLabels" -}}
app.kubernetes.io/name: {{ include "base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "base.metadata" -}}
metadata:
  name: {{ include "base.name" . }}
  labels:
    {{- include "base.labels" . | nindent 4 }}
{{- end -}}
