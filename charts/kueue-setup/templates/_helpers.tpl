{{/*
Expand the name of the chart.
*/}}
{{- define "kueue-setup.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kueue-setup.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "kueue-setup.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kueue-setup.labels" -}}
helm.sh/chart: {{ include "kueue-setup.chart" . }}
{{ include "kueue-setup.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kueue-setup.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kueue-setup.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Kueue controller webhook service name
*/}}
{{- define "kueue-setup.webhookServiceName" -}}
{{- printf "%s-kueue-controller-webhook-service" .Release.Name }}
{{- end }}

{{/*
Kueue controller webhook secret name
*/}}
{{- define "kueue-setup.webhookSecretName" -}}
{{- printf "%s-kueue-controller-webhook-server-cert" .Release.Name }}
{{- end }}

{{/*
Kueue controller mutating webhook configuration name
*/}}
{{- define "kueue-setup.mutatingWebhookName" -}}
{{- printf "%s-kueue-controller-mutating-webhook-configuration" .Release.Name }}
{{- end }}

{{/*
Kueue controller validating webhook configuration name
*/}}
{{- define "kueue-setup.validatingWebhookName" -}}
{{- printf "%s-kueue-controller-validating-webhook-configuration" .Release.Name }}
{{- end }}

{{/*
Kueue controller service account name
*/}}
{{- define "kueue-setup.controllerServiceAccountName" -}}
{{- printf "%s-kueue-controller-controller-manager" .Release.Name }}
{{- end }}
