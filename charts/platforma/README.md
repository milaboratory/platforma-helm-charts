![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![Version: 1.14.10](https://img.shields.io/badge/Version-1.14.10-informational?style=flat-square)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/platforma)](https://artifacthub.io/packages/helm/platforma/platforma)

Platfroma Backend
==============

For me information please visit the official documentation page [Platforma Backend](https://docs.platforma.bio/deployment/getting-started).

## Prerequisites

- Kubernetes 1.25+
- Helm 3.0+

## Installing

### Setting Up Secrets for `PL_LICENSE` and `MI_LICENSE`

#### Create the Secret Resource:
You need to create Kubernetes secrets that hold the license keys for `PL_LICENSE` and `MI_LICENSE`. You can do this using kubectl or include them in your Helm chart configurations.

Using kubectl:

```bash
kubectl create secret generic pl-license-secret --from-literal=pl-license-key='your_pl_license_key_here'
kubectl create secret generic mi-license-secret --from-literal=mi-license-key='your_mi_license_key_here'
```

Reference the Secrets in the Application:
Modify your application's deployment configuration to use these secrets. This is usually done in the envValueFrom section of the values.yaml file or directly in your application's configuration.

```yaml
app:
  envValueFrom:
    PL_LICENSE:
      secretKeyRef:
        name: pl-license-secret
        key: pl-license-key
    MI_LICENSE:
      secretKeyRef:
        name: mi-license-secret
        key: mi-license-key
```
You can also use the [External Secrets Operator](https://external-secrets.io), which is compatible with various secret management systems. For AWS environments, refer to the relevant configuration block in `values.yaml`:

```yaml
externalSecret:
  enabled: false
  awsRegion: eu-central-1
  # -- ExternalSecret annotations
  annotations: {}
  # -- ExternalSecret extra labels
  extraLabels: {}
  # -- SecretsStore target
  secretRefreshInterval: 24h
  secretStoreTarget: general-application-secrets
  secretDataFrom: {}
```
For this setup to function correctly on AWS, don’t forget to assign a role ARN with sufficient privileges to the service account managing the secrets.

### Configuring Access to an AWS S3 Bucket

When integrating an AWS S3 bucket with your application, you have two primary methods for managing access credentials:
œ
IAM Role:
Role-Based Access: Attach an IAM role to your service account or Kubernetes node. This role should have policies granting the necessary permissions to interact with the specified S3 bucket. This method is preferred in AWS as it does not require hard-coding credentials and offers more dynamic access control.
Example of assigning an IAM role to a service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/my-s3-access-role"
```  

Static Secrets:

Secrets Management: You can store AWS access and secret keys in Kubernetes secrets and reference them in your deployment configuration. This approach is less secure and generally recommended only when IAM roles cannot be used.
Example of creating a secret for S3 access:

```bash
kubectl create secret generic s3-credentials --from-literal=access-key-id='AKLLA.....FRRG' --from-literal=secret-access-key='wJalrX....hdkjfghk'
```

Referencing the secret in your deployment:

```yaml
env:
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: s3-credentials
        key: access-key-id
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: s3-credentials
        key: secret-access-key
```

### Configuring authentication
For the Platforma application, you have the option to use either htpasswd or LDAP for authentication. Below are the details on how to configure each method using the values.yaml file.

#### Using htpasswd for Authentication

If you choose to use htpasswd for authentication, you need to specify a list of users directly in the values.yaml file under the htpasswdConfig parameter. This method involves creating a hashed password for each user, which is then stored and referenced within the application.

Configure htpasswd in values.yaml:
Add user credentials in the htpasswdConfig parameter. Each user's password must be hashed, typically using bcrypt, MD5, or SHA.

```yaml
htpasswdConfig: |
    testuser:$apr1$0eub5f9s$QfkUyJqNcTj3TcbO3dcEI1
```

To generate a hashed password, you can use tools like htpasswd available in Apache HTTP Server or online bcrypt generators.

#### Using LDAP for Authentication
LDAP is a popular choice for centralized authentication, allowing users to log in with their credentials managed by an organization's directory services.

Configure LDAP in `values.yaml`:
Set the LDAP configuration parameters such as the server URL, bind DN, password, search base e.t.c

```yaml
config: |
  core:
    auth:
     - driver: ldap
       serverUrl: "ldap://ldap.chart-exmaple.local:3894"
       defaultDN: "cn=%u,ou=users,ou=users,dc=chart-example,dc=local"
```
