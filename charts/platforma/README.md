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
To enable this mode, use `docker.enabled: true` in values configuration.

NOTE: for now, 'docker' mode is restrictive, making backend to either require all software be binary (`enabled: false`) or be dockerized (`enabled: true`).

By default, docker pod gets created with the same resource requests/limits, as main service pod. It is possible to specify alternative resources for docker pod. Only options that are set to non-empty values will override common resource settings.
```yaml
docker:
  enabled: true
  resources:
    requests:
      memory: 256Gi
```

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

Reference the secrets in `values.yaml` under the appropriate section (e.g., `authOptions.ldap.tls`, `mainOptions.licenseFile.secretRef`, `primaryStorage.s3.secretRef`).

### 3. How It Works

The chart mounts the referenced secrets/configmaps as files into the pod at specific paths:
- LDAP client certificates: `/etc/platforma/secrets/ldap-client/` (from Secret) or `/etc/platforma/cm/ldap-client/` (from ConfigMap)
- LDAP CA certificates: `/etc/platforma/secrets/ldap-ca/` (from Secret) or `/etc/platforma/cm/ldap-ca/` (from ConfigMap)
The application is automatically configured to use these file paths.

### LDAP TLS Configuration

The chart provides a flexible way to configure TLS for LDAP connections, allowing you to secure communication with your directory server. You can configure a CA certificate to verify the server and a client certificate for mutual authentication (mTLS).

Certificates and keys can be provided from three sources, in order of precedence:
1.  **Kubernetes Secret** (`secretRef`): Recommended for sensitive data like private keys.
2.  **ConfigMap** (`configMapRef`): Suitable for public certificates like CAs.
3.  **File Path** (`path`): A direct path within the container's filesystem.

#### Verifying the LDAP Server with a CA Certificate

To make the application trust your LDAP server (especially if it uses a self-signed certificate or a private CA), you must provide a CA certificate.

**Example: CA from a ConfigMap**

1.  Create the ConfigMap:
    ```sh
    kubectl create configmap ldap-ca-cm --from-file=ca.crt=./my-ca.crt
    ```

2.  Reference it in `values.yaml`:
    ```yaml
    authOptions:
      ldap:
        enabled: true
        server: "ldaps://my-ldap-server:636"
        tls:
          enabled: true
          ca:
            configMapRef:
              enabled: true
              name: "ldap-ca-cm"
              key: "ca.crt"
    ```

#### Client Certificate Authentication (mTLS)

If your LDAP server requires clients to present a certificate, you can configure a client certificate and private key.

**Example: Client Cert/Key from a Secret**

1.  Create the Secret:
    ```sh
    kubectl create secret tls ldap-client-secret --cert=./client.crt --key=./client.key
    ```

2.  Reference it in `values.yaml`:
    ```yaml
    authOptions:
      ldap:
        enabled: true
        # ... other LDAP settings
        tls:
          enabled: true
          # You might also need a CA here
          client:
            secretRef:
              enabled: true
              name: "ldap-client-secret"
              certKey: "tls.crt" # Default key in a kubernetes.io/tls secret
              keyKey: "tls.key"  # Default key in a kubernetes.io/tls secret
    ```

#### System Root CA Certificates

You can configure system root CA certificates for LDAP authentication. This is useful when you need to specify a custom CA bundle for verifying LDAP server certificates. You can provide the root CA certificates via Secret, ConfigMap, or direct file path.

**Example: Root CA from a ConfigMap**

1.  Create the ConfigMap:
    ```sh
    kubectl create configmap ldap-root-cas-cm --from-file=ca.crt=./root-cas.crt
    ```

2.  Reference it in `values.yaml`:
    ```yaml
    authOptions:
      ldap:
        enabled: true
        server: "ldaps://my-ldap-server:636"
        rootCas:
          configMapRef:
            enabled: true
            name: "ldap-root-cas-cm"
            key: "ca.crt"
    ```

**Example: Root CA from a Secret**

1.  Create the Secret:
    ```sh
    kubectl create secret generic ldap-root-cas-secret --from-file=ca.crt=./root-cas.crt
    ```

2.  Reference it in `values.yaml`:
    ```yaml
    authOptions:
      ldap:
        enabled: true
        server: "ldaps://my-ldap-server:636"
        rootCas:
          secretRef:
            enabled: true
            name: "ldap-root-cas-secret"
            key: "ca.crt"
    ```

**Example: Root CA from a direct path**

If the root CA certificates are already available in the container filesystem:
    ```yaml
    authOptions:
      ldap:
        enabled: true
        server: "ldaps://my-ldap-server:636"
        rootCas:
          path: "/etc/ssl/certs/ca-certificates.crt"
    ```

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
-   **`volumes`**: Configures the shared NFS volume. Provide EITHER `existingClaim` (reuse an existing PVC) OR `storageClass` + `size` (let the chart create a PVC). Set `accessMode` as needed (default `ReadWriteMany`).

-   **`customJobTemplate`**: Provides a way to override the default Google Batch job structure.
    -   `enabled`: Set to `true` to use the custom template.
    -   `inline`: A multi-line string containing the job template JSON. A ConfigMap will be automatically created from this value. **Note:** This option is mutually exclusive with `configMap` - use only one.
    -   `configMap`: Reference a pre-existing ConfigMap by `name` and `key`. **Note:** This option is mutually exclusive with `inline` - use only one.

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
    existingClaim: "my-filestore-pvc" # or omit and set storageClass + size for dynamic provisioning
    accessMode: "ReadWriteMany"
    # storageClass: "filestore-rwx"
    # size: "1Ti"
  # Optional: Custom job template
  customJobTemplate:
    enabled: true
    # Option 1: Provide template inline (ConfigMap will be auto-created)
    inline: |
      {
        "allocationPolicy": {
          "location": {
            "allowedLocations": ["us-central1"]
          }
        }
      }
    # Option 2: Reference an existing ConfigMap (mutually exclusive with inline)
    # configMap:
    #   name: "my-batch-job-template"
    #   key: "job-template.json"
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
    # Default (sane for small clusters/testing)
    limits:
      cpu: 2000m
      memory: 4Gi
    requests:
      cpu: 1000m
      memory: 2Gi
  ```
  For production, consider increasing resources as needed, e.g.:
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
- **Ingress specifics**:
  - The HTTP port and `-http` Service exist only when `primaryStorage.fs.enabled` is true. The Ingress HTTP path is added only in that case. gRPC access is always via the main Service.
- **Traefik + gRPC (h2c)**:
  - If you use Traefik, you may need to enable h2c on the Service:
    ```yaml
    service:
      annotations:
        traefik.ingress.kubernetes.io/service.serversscheme: "h2c"
    ```
- **Image pull secrets**:
  - For private registries, set:
    ```yaml
    imagePullSecrets:
      - name: regcred
    ```
- **NetworkPolicy**:
  - Enable and define ingress/egress rules under `networkPolicy` if your cluster enforces them.
- **Security defaults**:
  - The chart defaults to running the container as root (`runAsUser: 0`). Consider hardening via `deployment.securityContext` and `deployment.podSecurityContext` to comply with cluster policies.

### Examples

Ready-to-use example values are provided under the `examples/` directory:

- `examples/hetzner-s3.yaml`
- `examples/aws-s3.yaml`
- `examples/gke-gcs.yaml`
- `examples/fs-primary.yaml`

> Important: Always review and adapt example files before deployment. Replace placeholders (bucket names, domains, storageClass, regions, service account emails, credentials) with values that match your environment and security policies.

### S3 credentials via Secret (example)

```sh
kubectl create secret generic my-s3-secret \
  --from-literal=access-key=AKIA... \
  --from-literal=secret-key=abcd1234...
```

```yaml
primaryStorage:
  s3:
    enabled: true
    url: "s3://my-bucket/primary/"
    region: "eu-central-1"
    secretRef:
      enabled: true
      name: my-s3-secret
      keyKey: access-key
      secretKey: secret-key
```
- **IAM Integration for AWS EKS and GCP GKE**:
  When running on managed Kubernetes services like AWS EKS or GCP GKE, it is common practice to associate Kubernetes service accounts with cloud IAM roles for fine-grained access control. You can add the necessary annotations to the `ServiceAccount` created by this chart using the `serviceAccount.annotations` value.

  **AWS EKS Example (IAM Roles for Service Accounts - IRSA):**
  ```yaml
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/MyPlatformaIAMRole"
  ```

  **GCP GKE Example (Workload Identity):**
  ```yaml
  serviceAccount:
    create: true
    annotations:
      iam.gke.io/gcp-service-account: "my-gcp-sa@my-gcp-project-id.iam.gserviceaccount.com"
  ```

## Minimal cloud permissions

When running on GKE with GCS/Batch or on EKS with S3, grant at least the following permissions to the cloud identity used by the chart.

### GCP (GKE + GCS + Google Batch)

Assign these roles to the GCP service account mapped via Workload Identity:

- roles/storage.objectAdmin
- roles/batch.jobsEditor
- roles/batch.agentReporter
- roles/iam.serviceAccountTokenCreator
- roles/artifactregistry.reader
- roles/logging.logWriter

### AWS (EKS + S3)

Attach an IAM policy similar to the following to the role mapped via IRSA. Substitute placeholders with your own values:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListEntireBucketAndMultipartActions",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": "arn:aws:s3:::example-bucket-name"
    },
    {
      "Sid": "FullAccessUserSpecific",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectAttributes",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "arn:aws:s3:::example-bucket-name/user-demo",
        "arn:aws:s3:::example-bucket-name/user-demo/*"
      ]
    },
    {
      "Sid": "GetObjectCommonPrefixes",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectAttributes"
      ],
      "Resource": [
        "arn:aws:s3:::example-bucket-name/corp-library/*",
        "arn:aws:s3:::example-bucket-name/test-assets/*"
      ]
    }
  ]
}
```
