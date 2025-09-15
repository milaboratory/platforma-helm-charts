[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/platforma)](https://artifacthub.io/packages/search?repo=platforma)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)
# Platforma Helm Chart

This Helm chart deploys the Platforma application to a Kubernetes cluster.

## Prerequisites

- **Helm**: v3.8.0+ (for OCI support)
- **Kubernetes**: v1.25.0+
- **Persistent Volume Provisioner**: A dynamic provisioner is required if you are using persistence (enabled by default).
- **Ingress Controller**: An Ingress controller (e.g., [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)) must be installed in the cluster to use the Ingress resource.

## Installation

There are two recommended methods for installing the Platforma Helm chart.

### Method 1: Install from OCI Registry (Recommended)

This is the preferred method for modern Helm versions. It pulls the chart directly from the GitHub Container Registry.

```sh
# Replace <version> with the specific chart version you want to install
# Replace <namespace> with the target namespace
# Provide your custom values file with -f
helm install my-platforma oci://ghcr.io/milaboratory/platforma-helm-charts/platforma \
  --version <version> \
  --namespace <namespace> \
  -f my-values.yaml
```

### Method 2: Install from Helm Repository

This method uses the traditional Helm repository hosted on GitHub Pages.

**1. Add the Helm Repository:**
```sh
helm repo add platforma https://milaboratory.github.io/platforma-helm-charts
helm repo update
```

**2. Install the Chart:**
```sh
# You can search for available versions
helm search repo platforma/platforma --versions

# Install the chart (replace <version> with the desired chart version)
# Replace <namespace> with the target namespace
# Provide your custom values file with -f
helm install my-platforma platforma/platforma \
  --version <version> \
  --namespace <namespace> \
  -f my-values.yaml
```

## Configuration overview

- **image**: repository, tag (defaults to `appVersion`), pullPolicy, `imagePullSecrets`.
- **service**: gRPC Service on `listenOptions.port` (default 6345). Optional HTTP Service only when `primaryStorage.fs.enabled` is true.
- **ingress**: Single `host`; gRPC path always when enabled; HTTP path only if `primaryStorage.fs.enabled`.
- **probes**: `httpGet`, `tcpSocket`, or `grpc`, separately configurable for liveness/readiness.
- **deployment**: strategy, pod labels/annotations, securityContext and podSecurityContext.
- **persistence**: either single `mainRoot` PVC or split `dbDir`/`workDir`/`packagesDir` PVCs; optional logging PVC; optional FS data libraries; optional FS primary storage PVC.
- **primaryStorage (exclusive)**: Exactly one of S3, FS, or GCS must be enabled; the chart validates this and fails otherwise.
- **dataLibrary**: Additional S3/GCS/FS libraries.
- **authOptions**: htpasswd or LDAP (+ TLS via paths or secretRef).
- **googleBatch**: CLI args and optional shared NFS PVC for offloaded jobs.
- **monitoring/debug**: Optional Services and ports.
 - **gcp.serviceAccount**: Optional centralized GCP service account email used as a fallback for GCS and Google Batch CLI options.
 - **gcp.projectId**: Optional centralized GCP Project ID used as a fallback for GCS and Google Batch CLI options.

## Migrating from 1.x to 2.0.0

Version `2.0.0` of this Helm chart introduces significant structural changes and is not backward-compatible with `1.x` versions. A manual migration is required to upgrade existing releases while preserving data.

The key change is the refactoring of the `values.yaml` file for better organization and clarity.

### Migration Steps

1.  **Backup Your Data**: Before starting the migration, ensure you have a backup of your persistent volumes.

2.  **Prepare a Migration `values.yaml`**:
    You will need to create a new values file (`migration-values.yaml`) that maps your old configuration to the new structure. The primary goal is to reuse your existing PersistentVolumeClaims (PVCs) to avoid data loss.

    Your existing PVCs typically follow this naming pattern:
    - `<release-name>-platforma-database`
    - `<release-name>-platforma-work`
    - `<release-name>-platforma-softwareloader`

3.  **Map Old Values to New Structure**:
    Here is an example of how to configure the `persistence` section in your `migration-values.yaml` to reuse your existing volumes:

    ```yaml
    # migration-values.yaml

    persistence:

      dbDir:
        enabled: true
        existingClaim: "<release-name>-platforma-database"
        mountPath: "/db"

      workDir:
        enabled: true
        existingClaim: "<release-name>-platforma-work"
        mountPath: "/data/work"

      packagesDir:
        enabled: true
        existingClaim: "<release-name>-platforma-softwareloader"
        mountPath: "/storage/controllers/software-loader"
    ```

    You must also port other custom configurations from your old `values.yaml` (e.g., `image.tag`, `ingress`, `resources`, `primaryStorage`, `authOptions`) to their new locations in the `platforma` structure.

4.  **Perform the Upgrade**:
    Run `helm upgrade` with your release name, the new chart version, and your migration values file.

    ```sh
    helm upgrade <release-name> platforma/platforma --version 2.0.0 -f migration-values.yaml
    ```

## Configuration

### Passing Licenses as Environment Variables

You can pass licenses for Platforma (`PL_LICENSE`) and other integrated tools (`MI_LICENSE`) securely using Kubernetes Secrets and environment variables.

**1. Create the Secret Resources**

Create Kubernetes secrets to hold your license keys.

Using `kubectl`:
```sh
kubectl create secret generic pl-license-secret --from-literal=pl-license-key='your_pl_license_key_here'
kubectl create secret generic mi-license-secret --from-literal=mi-license-key='your_mi_license_key_here'
```

**2. Reference the Secrets in `values.yaml`**

Modify your `values.yaml` to reference these secrets. The chart will inject them as environment variables into the application container.

```yaml
env:
  secretVariables:
    - name: PL_LICENSE
      secretKeyRef:
        name: pl-license-secret
        key: pl-license-key
    - name: MI_LICENSE
      secretKeyRef:
        name: mi-license-secret
        key: mi-license-key
```


### Persistence

Persistence is enabled by default and controlled under `persistence`:

- Remove the former `globalEnabled`; behavior now depends on `mainRoot.enabled` vs split volumes.
- **mainRoot (default)**: a single PVC mounted at `persistence.mainRoot.mountPath` (default `/data/platforma-data`). When `mainRoot.enabled: true`, the split volumes below are ignored.
- **Split volumes**: only used when `mainRoot.enabled: false`:
  - `dbDir`: RocksDB state
  - `workDir`: working directory
  - `packagesDir`: software packages
  For each you can set `existingClaim` to use existing PersistentVolumeClaim instead of automatic PVC creation for service 
  Also you can alter `size` and `storageClass`.
- **Logging persistence**: when `logging.destination` is `dir://` or `file://`, you can persist logs with `logging.persistence.enabled`. Configuration rules are the same as for other persistent volumes.
- **FS data libraries**: each entry in `dataLibrary.fs` can create or reuse a PVC and is mounted at its `path`.

Tip: set `existingClaim` to reuse an existing volume; otherwise set `createPvc: true` and specify `size` (and `storageClass` if needed).

---

### Docker

Platforma Backend can use docker images to run software for blocks.
To enable this mode, use `useDocker: true` in values configuration.

NOTE: for now, 'docker' mode is restrictive, making backend to either require all software be binary (`useDocker: false`) or be dockerized (`useDocker: true`).

## Securely Passing Files with Secrets

For sensitive files like TLS certificates, S3 credentials, or the Platforma license file, this chart uses a secure mounting mechanism.

### 1. Create Kubernetes Secrets

You can create secrets from files or literal values.

- **LDAP Certificates**:
  ```sh
  kubectl create secret generic ldap-cert-secret \
    --from-file=tls.crt=./tls.crt \
    --from-file=tls.key=./tls.key \
    --from-file=ca.crt=./ca.crt
  ```
- **Platforma License File**:
  ```sh
  kubectl create secret generic platforma-license \
    --from-file=license=./license.txt
  ```
- **S3 Credentials**:
  ```sh
  kubectl create secret generic my-s3-secret \
    --from-literal=access-key=AKIA... \
    --from-literal=secret-key=abcd1234...
  ```

### 2. Reference Secrets in `values.yaml`

Reference the secrets in `values.yaml` under the appropriate section (e.g., `authOptions.ldap.secretRef`, `mainOptions.licenseFile.secretRef`, `primaryStorage.s3.secretRef`).

### 3. How It Works

The chart mounts the referenced secret as files into the pod (e.g., at `/etc/platforma/secrets/ldap/`), and the application is automatically configured to use these file paths.

---

## Storage Configuration

This Helm chart provides flexible options for both primary and data library storage, allowing you to use S3, GCS, or a local filesystem (via PersistentVolumeClaims).

### Primary Storage

Primary storage is used for long-term storage of analysis results. Only one primary storage provider can be enabled at a time.

- **S3**: To use an S3-compatible object store, configure the `primaryStorage.s3` section. You can provide credentials directly or reference a Kubernetes secret.
- **GCS**: To use Google Cloud Storage, configure `primaryStorage.gcs`, specifying the bucket URL, project ID, and service account.
- **FS (Filesystem)**: To use a local filesystem path backed by a PVC, enable `primaryStorage.fs`.
  - If `primaryStorage.fs.persistence.enabled` is true:
    - Use `existingClaim` to reuse a PVC, OR
    - Provide `storageClass` and `size` to let the chart create a PVC.
  - The chart will attach the `primary-storage` volume automatically when `primaryStorage.fs.persistence.enabled` is true.

#### Example GCS Configuration

```yaml
gcp:
  projectId: "my-gcp-project-id" # optional centralized project

primaryStorage:
  gcs:
    enabled: true
    url: "gs://my-gcs-bucket/primary-storage/"
    # projectId can be omitted; will use gcp.projectId when set
    # Optional if you set top-level gcp.serviceAccount (see below)
    # serviceAccount: "my-gcs-service-account@my-gcp-project-id.iam.gserviceaccount.com"
```

#### Example: Hetzner (S3-compatible) credentials

For S3-compatible endpoints (e.g., Hetzner), set AWS-style env variables and a Secret for access/secret:

```sh
kubectl create secret generic hetzner-s3-credentials \
  --from-literal=access-key=ACCESS_KEY \
  --from-literal=secret-key=SECRET_KEY
```

In values:

```yaml
env:
  variables:
    AWS_REGION: eu-central-1
  secretVariables:
    - name: AWS_ACCESS_KEY_ID
      secretKeyRef:
        name: hetzner-s3-credentials
        key: access-key
    - name: AWS_SECRET_ACCESS_KEY
      secretKeyRef:
        name: hetzner-s3-credentials
        key: secret-key
```

#### Primary Storage validation (important)

Exactly one of `primaryStorage.s3.enabled`, `primaryStorage.fs.enabled`, or `primaryStorage.gcs.enabled` must be true. The chart validates this at render time and will fail if none or multiple are enabled.

### Data Libraries

Data libraries allow you to mount additional datasets into the application. You can configure multiple libraries of different types.

- **S3 Libraries**: Configure S3-backed libraries under `dataLibrary.s3`.
- **GCS Libraries**: Configure GCS-backed libraries under `dataLibrary.gcs`.
- **FS Libraries**: Configure filesystem-backed libraries under `dataLibrary.fs`, which will be provisioned using PVCs.

#### Example GCS Data Libraries

```yaml
gcp:
  # Centralized service account and project used as fallback for GCS options below
  serviceAccount: "my-gcp-sa@my-gcp-project-id.iam.gserviceaccount.com"
  projectId: "my-gcp-project-id"

dataLibrary:
  gcs:
    - id: "library"
      enabled: true
      url: "gs://my-gcs-bucket/corp-library/"
      # projectId omitted; will use gcp.projectId
      # serviceAccount can be omitted because gcp.serviceAccount is set
      # serviceAccount: "my-gcp-sa@my-gcp-project-id.iam.gserviceaccount.com"
    - id: "test-assets"
      enabled: true
      url: "gs://my-gcs-bucket/test-assets/"
      # projectId omitted; will use gcp.projectId
```

### Google Batch Integration

This chart supports integration with Google Batch for offloading job execution. This is useful for large-scale data processing tasks. To enable this, you need a shared filesystem (like NFS) that is accessible by both the Platforma pod and the Google Batch jobs. Google Cloud Filestore is a common choice for this.

**Configuration:**

The `googleBatch` section in `values.yaml` controls this integration.

-   **`enabled`**: Set to `true` to enable Google Batch integration.
-   **`storage`**: Specifies the mapping between a local path in the container and the shared NFS volume. The format is `<local-path>=<nfs-uri>`.
-   **`project`**: Your Google Cloud Project ID.
-   **`region`**: The GCP region where Batch jobs will run.
-   **`
