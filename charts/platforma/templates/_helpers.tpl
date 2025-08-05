# Expand the name of the chart.
{{- define "platforma.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Create a default fully qualified app name.
# We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
# If release name contains chart name it will be used as a full name.
{{- define "platforma.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

# Create chart name and version as used by the chart label.
{{- define "platforma.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Common labels
{{- define "platforma.labels" -}}
helm.sh/chart: {{ include "platforma.chart" . }}
{{ include "platforma.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

# Selector labels
{{- define "platforma.selectorLabels" -}}
app.kubernetes.io/name: {{ include "platforma.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

# Create the name of the service account to use
{{- define "platforma.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "platforma.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{- default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

# Gathers all *enabled* PVC configurations.
{{- define "platforma.allPvcs" -}}
{{- $allPvcs := dict -}}
{{- if .Values.persistence.globalEnabled -}}
  {{- if .Values.persistence.mainRoot.enabled -}}
    {{- $_ := set $allPvcs "main-root" .Values.persistence.mainRoot -}}
  {{- else -}}
    {{- if .Values.persistence.dbDir.enabled -}}
      {{- $_ := set $allPvcs "db" .Values.persistence.dbDir -}}
    {{- end -}}
    {{- if and .Values.persistence.workDir.enabled (not .Values.googleBatch.enabled) -}}
      {{- $_ := set $allPvcs "work" .Values.persistence.workDir -}}
    {{- end -}}
    {{- if and .Values.persistence.packagesDir.enabled (not .Values.googleBatch.enabled) -}}
      {{- $_ := set $allPvcs "packages" .Values.persistence.packagesDir -}}
    {{- end -}}
  {{- end -}}
  {{- if and (hasPrefix "dir://" .Values.logging.destination) .Values.logging.persistence.enabled -}}
    {{- $_ := set $allPvcs "logs" .Values.logging.persistence -}}
  {{- end -}}
{{- end -}}
{{- if and .Values.primaryStorage.fs.enabled .Values.primaryStorage.fs.pvc.enabled -}}
  {{- $_ := set $allPvcs "primary-storage" .Values.primaryStorage.fs.pvc -}}
{{- end -}}
{{- range .Values.dataLibrary.fs -}}
  {{- if .pvc.enabled -}}
    {{- $_ := set $allPvcs .id .pvc -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" (mustToJson $allPvcs) -}}
{{- end -}}

# Constructs a list of volumes to be mounted to the main application container.
# This helper gathers all enabled PVC configurations, determines whether to use an
# existing claim or a generated one, and creates the corresponding volume definition.
{{- define "platforma.volumes" -}}
{{- $allPvcs := fromJson (include "platforma.allPvcs" .) -}}
{{- range $key, $pvc := $allPvcs -}}
{{- if or $pvc.existingClaim $pvc.createPvc }}
- name: {{ $key | trunc 63 | trimSuffix "-" }}
  persistentVolumeClaim:
    claimName: {{ $pvc.existingClaim | default (printf "%s-%s" (include "platforma.fullname" $) $key | trunc 63 | trimSuffix "-") | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

# Constructs a list of volume mounts for the main application container.
# This helper gathers all enabled PVC configurations and creates the corresponding
# volumeMount definition with the correct name and mount path.
{{- define "platforma.volumeMounts" -}}
{{- $allPvcs := fromJson (include "platforma.allPvcs" .) -}}
{{- range $key, $pvc := $allPvcs -}}
{{- if or $pvc.existingClaim $pvc.createPvc }}
- name: {{ $key | trunc 63 | trimSuffix "-" }}
  mountPath: {{ $pvc.mountPath }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate Primary Storage Configuration
This helper template checks that exactly one primary storage option (s3, fs, or gcs) is enabled.
It will fail the template rendering with an error message if the configuration is invalid.
*/}}
{{- define "platforma.validatePrimaryStorage" -}}
{{- $enabled := list -}}
{{- if .Values.primaryStorage.s3.enabled -}}
  {{- $enabled = append $enabled "s3" -}}
{{- end -}}
{{- if .Values.primaryStorage.fs.enabled -}}
  {{- $enabled = append $enabled "fs" -}}
{{- end -}}
{{- if .Values.primaryStorage.gcs.enabled -}}
  {{- $enabled = append $enabled "gcs" -}}
{{- end -}}
{{- if gt (len $enabled) 1 }}
  {{- fail (printf "Only one primary storage can be enabled at a time, but got: %s" (join ", " $enabled)) -}}
{{- end -}}
{{- if not $enabled }}
  {{- fail "At least one primary storage must be enabled. Please enable one of: s3, fs, or gcs." -}}
{{- end -}}
{{- end -}}