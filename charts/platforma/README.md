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
helm install my-platforma oci://ghcr.io/milaboratory/platforma-helm-charts/platforma --version <version>
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
helm install my-platforma platforma/platforma --version <version>
```

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
      globalEnabled: true

      dbDir:
        enabled: true
        createPvc: false # Important: Set to false to use existing PVC
        existingClaim: "<release-name>-platforma-database"
        mountPath: "/db"

      workDir:
        enabled: true
        createPvc: false # Important: Set to false to use existing PVC
        existingClaim: "<release-name>-platforma-work"
        mountPath: "/data/work"

      packagesDir:
        enabled: true
        createPvc: false # Important: Set to false to use existing PVC
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

The chart uses PersistentVolumeClaims (PVCs) to store application data, ensuring that your data is not lost if the pod restarts. Persistence is enabled by default and can be configured under the `persistence` section in `values.yaml`.

---

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

#### Example GCS Configuration

```yaml
primaryStorage:
  gcs:
    enabled: true
    url: "gs://my-gcs-bucket/primary-storage/"
    projectId: "my-gcp-project-id"
    serviceAccount: "my-gcs-service-account@my-gcp-project-id.iam.gserviceaccount.com"
```

### Data Libraries

Data libraries allow you to mount additional datasets into the application. You can configure multiple libraries of different types.

- **S3 Libraries**: Configure S3-backed libraries under `dataLibrary.s3`.
- **GCS Libraries**: Configure GCS-backed libraries under `dataLibrary.gcs`.
- **FS Libraries**: Configure filesystem-backed libraries under `dataLibrary.fs`, which will be provisioned using PVCs.

### Google Batch Integration

This chart supports integration with Google Batch for offloading job execution. This is useful for large-scale data processing tasks. To enable this, you need a shared filesystem (like NFS) that is accessible by both the Platforma pod and the Google Batch jobs. Google Cloud Filestore is a common choice for this.

**Configuration:**

The `googleBatch` section in `values.yaml` controls this integration.

-   **`enabled`**: Set to `true` to enable Google Batch integration.
-   **`storage`**: Specifies the mapping between a local path in the container and the shared NFS volume. The format is `<local-path>=<nfs-uri>`.
-   **`project`**: Your Google Cloud Project ID.
-   **`region`**: The GCP region where Batch jobs will run.
-   **`serviceAccount`**: The email of the GCP service account that Google Batch jobs will use. This service account needs appropriate permissions for Batch and storage access.
-   **`network` / `subnetwork`**: The VPC network and subnetwork for the Batch jobs.
-   **`volumes`**: This section configures the PersistentVolumeClaim for the shared NFS volume. You must provide the `existingClaim` name for your pre-provisioned NFS PVC (e.g., from Filestore).

**Example Configuration:**

```yaml
googleBatch:
  enabled: true
  storage: "/data/platforma-data=nfs://10.0.0.2/fileshare"
  project: "my-gcp-project-id"
  region: "us-central1"
  serviceAccount: "batch-executor@my-gcp-project-id.iam.gserviceaccount.com"
  network: "projects/my-gcp-project-id/global/networks/default"
  subnetwork: "projects/my-gcp-project-id/regions/us-central1/subnetworks/default"
  volumes:
    enabled: true
    existingClaim: "my-filestore-pvc"
    accessMode: "ReadWriteMany"
```

This configuration assumes you have already created a Google Cloud Filestore instance and a corresponding PersistentVolumeClaim (`my-filestore-pvc`) in your Kubernetes cluster.

#### Example S3 Data Library

```yaml
dataLibrary:
  s3:
    - id: "my-s3-library"
      enabled: true
      url: "s3://my-s3-bucket/path/to/library/"
      region: "us-east-1"
```

---

## Logging Configuration

The chart offers flexible logging options configured via the `logging.destination` parameter in `values.yaml`.

- **Stream-Based Logging (Default)**:
  - `stream://stdout`: Logs are sent to standard output (recommended for Kubernetes).
  - `stream://stderr`: Logs are sent to standard error.

- **Directory-Based Logging**:
  - `dir:///path/to/logs`: Logs are written to files in the specified directory. To persist logs, enable `logging.persistence` in `values.yaml`, which will create a PersistentVolumeClaim (PVC) to store the log files.

#### Example: Persistent Logging to a Directory

```yaml
logging:
  destination: "dir:///var/log/platforma"
  persistence:
    enabled: true
    size: 10Gi
    storageClass: "standard"
```

---

## Production Considerations

When deploying to a production environment, consider the following:

- **Resource Management**: Set realistic CPU and memory `requests` and `limits` in the `resources` section to ensure stable performance. For example:
  ```yaml
  resources:
    limits:
      cpu: 8000m
      memory: 16Gi
    requests:
      cpu: 4000m
      memory: 8Gi
  ```
- **Security**:
  - Use a dedicated `serviceAccount` and link it to a cloud IAM role for secure access to cloud resources.
  - Configure the `deployment.securityContext` and `podSecurityContext` to run the application with the least required privileges.
- **Networking**:
  - For secure external access, configure the `ingress` with a real TLS certificate.
  - Use `networkPolicy` to restrict traffic between pods for a more secure network posture.
