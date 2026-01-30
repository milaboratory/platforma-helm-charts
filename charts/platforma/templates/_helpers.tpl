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

{{/*
Returns the GCP service account to use, preferring explicit fields and falling back to .Values.gcp.serviceAccount
*/}}
{{- define "platforma.gcpServiceAccount" -}}
{{- $sa := "" -}}
{{- if .Values.gcp.serviceAccount -}}
  {{- $sa = .Values.gcp.serviceAccount -}}
{{- end -}}
{{- if and (not $sa) .Values.primaryStorage.gcs.serviceAccount -}}
  {{- $sa = .Values.primaryStorage.gcs.serviceAccount -}}
{{- end -}}
{{- if and (not $sa) .Values.googleBatch.serviceAccount -}}
  {{- $sa = .Values.googleBatch.serviceAccount -}}
{{- end -}}
{{- $sa -}}
{{- end -}}

# Gathers all *enabled* PVC configurations.
# Note: mainRoot is always included. workDir and packagesDir are subfolders within mainRoot.
{{- define "platforma.allPvcs" -}}
  {{- $allPvcs := dict -}}
  {{- /* mainRoot is always created */ -}}
  {{- $_ := set $allPvcs "main-root" .Values.persistence.mainRoot -}}
  {{- /* dbDir can optionally be a separate PVC */ -}}
  {{- if .Values.persistence.dbDir.enabled -}}
    {{- $_ := set $allPvcs "db" .Values.persistence.dbDir -}}
  {{- end -}}

  {{- if .Values.logging.persistence.enabled -}}
    {{- $logsPvc := .Values.logging.persistence | deepCopy -}}

    {{- if hasPrefix "dir://" .Values.logging.destination -}}
      {{- $dirPath := trimPrefix "dir://" .Values.logging.destination -}}

      {{- if eq $dirPath "/" -}}
        {{- fail "Logging persistence is enabled, but log dir points to root (/). Disable persistence for logs or specify subdirectory" -}}
      {{- end -}}
      {{- if not (hasPrefix "/" $dirPath) -}}
        {{- fail "Logging persistence is enabled, but log dir is not an absolute path. Disable persistence for logs or specify absolute path" -}}
      {{- end -}}

      {{- $_ := set $logsPvc "mountPath" $dirPath -}}
      {{- $_ := set $allPvcs "logs" $logsPvc -}}
    {{- end -}}

    {{- if hasPrefix "file://" .Values.logging.destination -}}
      {{- $filePath := trimPrefix "file://" .Values.logging.destination -}}
      {{- $dirPath := dir $filePath -}}

      {{- if eq $dirPath "/" -}}
        {{- fail "Logging persistence is enabled, but log file points to root (/). Disable persistence for logs or specify subdirectory" -}}
      {{- end -}}
      {{- if not (hasPrefix "/" $dirPath) -}}
        {{- fail "Logging persistence is enabled, but log file is not an absolute path. Disable persistence for logs or specify absolute path" -}}
      {{- end -}}

      {{- $_ := set $logsPvc "mountPath" $dirPath -}}
      {{- $_ := set $allPvcs "logs" $logsPvc -}}
    {{- end -}}

  {{- end -}}

  {{- if and .Values.primaryStorage.fs.enabled .Values.primaryStorage.fs.persistence.enabled -}}
    {{- $_ := set $allPvcs "primary-storage" .Values.primaryStorage.fs.persistence -}}
  {{- end -}}

  {{- range .Values.dataLibrary.fs -}}
    {{- if .persistence.enabled -}}
      {{- $_ := set $allPvcs .id .persistence -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s" (mustToJson $allPvcs) -}}
{{- end -}}

{{/*
Validate Persistence Configuration
This helper enforces:
- mainRoot is always enabled (always created)
- workDir and packagesDir are subfolders within mainRoot
- dbDir can optionally be a separate PVC
*/}}
{{- define "platforma.validatePersistence" -}}
  {{- /* mainRoot is always enabled, no validation needed */ -}}
{{- end -}}

{{/*
Constructs a list of volumes to be mounted to the main application container.
This helper gathers all enabled PVC configurations, determines whether to use an
existing claim or a generated one, and creates the corresponding volume definition.
*/}}
{{- define "platforma.volumes" -}}
  {{- $allPvcs := fromJson (include "platforma.allPvcs" .) -}}
  {{- range $key, $pvc := $allPvcs }}
- name: {{ $key | trunc 63 | trimSuffix "-" }}
  persistentVolumeClaim:
    claimName: {{ $pvc.existingClaim | default (printf "%s-%s" (include "platforma.fullname" $) $key | trunc 63 | trimSuffix "-") | quote }}
  {{- end -}}
{{- end -}}

{{/*
Constructs a list of volume mounts for the main application container.
This helper gathers all enabled PVC configurations and creates the corresponding
volumeMount definition with the correct name and mount path.
*/}}
{{- define "platforma.volumeMounts" -}}
  {{- $allPvcs := fromJson (include "platforma.allPvcs" .) -}}
  {{- range $key, $pvc := $allPvcs }}
- name: {{ $key | trunc 63 | trimSuffix "-" }}
  mountPath: {{ $pvc.mountPath }}
  {{- end -}}
{{- end -}}
{{/*
Constructs a list of shared volumes that should be mounted into additional pods (i.e. Docker-in-Docker pod)
*/}}
{{- define "platforma.sharedVolumes" -}}
  {{- $allPvcs := fromJson (include "platforma.allPvcs" .) -}}
  {{- range $key, $pvc := $allPvcs }}
    {{- if eq $key "main-root" }}
- name: {{ $key | trunc 63 | trimSuffix "-" }}
  persistentVolumeClaim:
    claimName: {{ $pvc.existingClaim | default (printf "%s-%s" (include "platforma.fullname" $) $key | trunc 63 | trimSuffix "-") | quote }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Constructs a list of volume mounts for the shared volumes that should be mounted into
additional pods (i.e. Docker-in-Docker pod)
*/}}
{{- define "platforma.sharedVolumeMounts" -}}
  {{- $allPvcs := fromJson (include "platforma.allPvcs" .) -}}
  {{- range $key, $pvc := $allPvcs -}}
    {{- if eq $key "main-root" }}
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

{{/*
Generate value for DOCKER_HOST env variable: TCP URL pointing to the docker service.
*/}}
{{- define "platforma.dockerHost" -}}
  {{- printf "tcp://%s-docker:2375" (include "platforma.fullname" .) -}}
{{- end -}}

{{/*
Parse CPU resource value and convert to whole CPUs (minimum 1).
Handles formats like: "2000m", "2", "0.5", etc.
Returns an integer representing whole CPUs.
*/}}
{{- define "platforma.parseCpuToWholeCpus" -}}
  {{- $cpu := . | toString -}}
  {{- if hasSuffix "m" $cpu -}}
    {{- $cpu = divf (float64 (trimSuffix "m" $cpu)) 1000.0 -}}
  {{- else -}}
    {{- $cpu = float64 $cpu -}}
  {{- end -}}
  {{- maxf (ceil $cpu) 1.0 | int -}}
{{- end -}}

{{/*
Docker resource limits and requests.
Use common resources section, overriding particular values if they are not empty in docker
*/}}
{{- define "platforma.dockerResources" -}}
  {{- $resources := .Values.resources | deepCopy -}}

  {{- if .Values.docker.resources.limits.cpu -}}
    {{- $_ := set $resources.limits "cpu" .Values.docker.resources.limits.cpu -}}
  {{- end -}}
  {{- if .Values.docker.resources.limits.memory -}}
    {{- $_ := set $resources.limits "memory" .Values.docker.resources.limits.memory -}}
  {{- end -}}
  {{- if .Values.docker.resources.requests.cpu -}}
    {{- $_ := set $resources.requests "cpu" .Values.docker.resources.requests.cpu -}}
  {{- end -}}
  {{- if .Values.docker.resources.requests.memory -}}
    {{- $_ := set $resources.requests "memory" .Values.docker.resources.requests.memory -}}
  {{- end -}}

  {{- toYaml $resources -}}
{{- end -}}

{{/*
Create the name of the platforma-data PVC.
*/}}
{{- define "platforma.platformaDataPvcName" -}}
{{- printf "%s-platforma-data" (include "platforma.fullname" .) -}}
{{- end -}}

{{/*
Returns the main root mount path.
*/}}
{{- define "platforma.instanceMainRootMountPath" -}}
{{- printf "%s/%s" .Values.persistence.mainRoot.mountPath .Values.persistence.mainRoot.dataPath -}}
{{- end -}}

{{/*
Returns the full path to the work directory (mountPath/workDirName).
*/}}
{{- define "platforma.mainRootWorkDir" -}}
{{- printf "%s/%s" (include "platforma.instanceMainRootMountPath" .) .Values.persistence.mainRoot.workDirName -}}
{{- end -}}

{{/*
Returns the full path to the common directory (mountPath/dataPath/common).
*/}}
{{- define "platforma.mainRootCommonDir" -}}
{{- printf "%s/common" (include "platforma.instanceMainRootMountPath" .) -}}
{{- end -}}
