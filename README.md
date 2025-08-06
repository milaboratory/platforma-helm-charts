-[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/platforma)](https://artifacthub.io/packages/search?repo=platforma)
-![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)
# Platforma Helm Chart

This Helm chart deploys the Platforma application to a Kubernetes cluster.

## Prerequisites

- **Helm**: v3.0.0+
- **Kubernetes**: v1.19.0+
- **Persistent Volume Provisioner**: A dynamic provisioner is required if you are using persistence (enabled by default).
- **Ingress Controller**: An Ingress controller (e.g., [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)) must be installed in the cluster to use the Ingress resource.

## Quick Start Guide

To install the chart with the release name `my-platforma`:

```sh
# Add the chart repository (replace with your actual repo URL)
helm repo add platforma https://milaboratory.github.io/platforma-helm-charts

# Update your local chart repository cache
helm repo update

# Install the chart
helm install my-platforma platforma/platforma
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

### Runner Options

The `runnerOptions` section controls the resources available for local execution.

- **`localCpu`** and **`localRam`**: These values determine the CPU and RAM allocated for local jobs. **Crucially, if you leave these fields empty, they will automatically align with the pod's resource limits** (`resources.limits.cpu` and `resources.limits.memory`). This is the recommended approach to ensure the runner does not exceed the resources allocated to the pod.

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

### Google Batch

When using Google Batch for job execution, you can specify a dedicated service account for the batch jobs.

- **`googleBatch.serviceAccount`**: The email address of the GCP service account to be used for running Google Batch jobs.

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

- **Resource Management**: Set realistic CPU and memory `requests` and `limits` in the `resources` section to ensure stable performance.
- **Security**:
  - Use a dedicated `serviceAccount` and link it to a cloud IAM role for secure access to cloud resources.
  - Configure the `deployment.securityContext` and `deployment.podSecurityContext` to run the application with the least required privileges.
- **Networking**:
  - For secure external access, configure the `ingress` with a real TLS certificate.
  - Use `networkPolicy` to restrict traffic between pods for a more secure network posture.
