{{/*
Expand the name of the chart.
*/}}
{{- define "openvoxdb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PostgreSQL resource name.
*/}}
{{- define "openvoxdb.postgresqlFullname" -}}
{{- printf "%s-postgresql" (include "openvoxdb.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
PostgreSQL hostname used by OpenVoxDB.
*/}}
{{- define "openvoxdb.postgresqlHostname" -}}
{{- if .Values.postgresql.internal.enabled -}}
{{- include "openvoxdb.postgresqlFullname" . -}}
{{- else -}}
{{- required "postgresql.external.hostname is required when postgresql.internal.enabled is false" .Values.postgresql.external.hostname -}}
{{- end -}}
{{- end }}

{{/*
PostgreSQL credential Secret name.
*/}}
{{- define "openvoxdb.postgresqlSecretName" -}}
{{- default (include "openvoxdb.postgresqlFullname" .) .Values.postgresql.shared.existingSecret -}}
{{- end }}

{{/*
PostgreSQL selector labels.
*/}}
{{- define "openvoxdb.postgresqlSelectorLabels" -}}
{{ include "openvoxdb.selectorLabels" . }}
app.kubernetes.io/component: postgresql
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "openvoxdb.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openvoxdb.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "openvoxdb.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openvoxdb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openvoxdb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openvoxdb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openvoxdb.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
