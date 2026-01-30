# Kueue Setup Helm Chart

A Helm chart for installing and configuring [Kueue](https://kueue.sigs.k8s.io/) - a Kubernetes-native job queue management system.

## Features

- Installs Kueue controller as a subchart
- Creates ResourceFlavor, ClusterQueue, and LocalQueue resources
- Configurable `waitForPodsReady` for all-or-nothing scheduling
- Configurable `objectRetentionPolicies` for workload garbage collection
- Automatic webhook CA bundle patching

## Prerequisites

- Kubernetes cluster v1.25+
- Helm v3.x
- kubectl configured to access the cluster

## Installation

### Add Helm Repository

```bash
helm repo add platforma https://milaboratory.github.io/platforma-helm-charts
helm repo update
```

### Basic Installation

```bash
helm install kueue platforma/kueue-setup \
  --namespace kueue-system \
  --create-namespace
```

### Installation with Custom Configuration

```bash
helm install kueue platforma/kueue-setup \
  --namespace kueue-system \
  --create-namespace \
  --values my-values.yaml
```

## Configuration

### Queue Resources

```yaml
queues:
  enabled: true
  resourceFlavor:
    name: "default"
  clusterQueue:
    name: "cluster-queue"
    resources:
      cpu: "32"
      memory: "64Gi"
  localQueue:
    name: "local-queue"
```

### Kueue Controller with waitForPodsReady and objectRetentionPolicies

```yaml
kueue-controller:
  managerConfig:
    controllerManagerConfigYaml: |
      apiVersion: config.kueue.x-k8s.io/v1beta1
      kind: Configuration
      namespace: kueue-system
      health:
        healthProbeBindAddress: :8081
      metrics:
        bindAddress: :8443
      webhook:
        port: 9443
      leaderElection:
        leaderElect: true
        resourceName: c1f6bfd2.kueue.x-k8s.io
      controller:
        groupKindConcurrency:
          Job.batch: 5
          Pod: 5
          Workload.kueue.x-k8s.io: 5
          LocalQueue.kueue.x-k8s.io: 1
          ClusterQueue.kueue.x-k8s.io: 1
          ResourceFlavor.kueue.x-k8s.io: 1
      clientConnection:
        qps: 50
        burst: 100
      # IMPORTANT: Update these names to match your release name
      internalCertManagement:
        enable: true
        webhookServiceName: kueue-kueue-controller-webhook-service
        webhookSecretName: kueue-kueue-controller-webhook-server-cert
      integrations:
        frameworks:
        - "batch/job"
      # WaitForPodsReady - all-or-nothing scheduling
      # Evicts workloads if pods don't become ready within timeout
      waitForPodsReady:
        enable: true
        timeout: 5m                   # Time for pods to become ready
        recoveryTimeout: 3m           # Time for running workloads with failing pods
        blockAdmission: false
        requeuingStrategy:
          timestamp: Eviction
          backoffLimitCount: 5        # Max requeue attempts (null = infinite)
          backoffBaseSeconds: 60
          backoffMaxSeconds: 3600
      # Garbage collection of finished workloads
      objectRetentionPolicies:
        workloads:
          afterFinished: "1h"           # Delete finished workloads after 1 hour
          afterDeactivatedByKueue: "30m" # Delete evicted workloads after 30 minutes
```

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controller.enabled` | Enable Kueue controller subchart | `true` |
| `queues.enabled` | Enable queue resources creation | `true` |
| `queues.resourceFlavor.name` | ResourceFlavor name | `"default"` |
| `queues.clusterQueue.name` | ClusterQueue name | `"cluster-queue"` |
| `queues.clusterQueue.resources.cpu` | CPU quota | `"32"` |
| `queues.clusterQueue.resources.memory` | Memory quota | `"64Gi"` |
| `queues.localQueue.name` | LocalQueue name | `"local-queue"` |
| `caPatcher.enabled` | Enable CA bundle patcher | `true` |
| `caPatcher.timeout` | Timeout waiting for cert secret | `300` |

## Usage

### Submit a Job to Kueue

Add the `kueue.x-k8s.io/queue-name` label to your Job:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
  labels:
    kueue.x-k8s.io/queue-name: local-queue
spec:
  template:
    spec:
      containers:
        - name: worker
          image: busybox:1.36
          command: ["echo", "Hello from Kueue!"]
          resources:
            requests:
              cpu: "100m"
              memory: "64Mi"
      restartPolicy: Never
```

### Check Workload Status

```bash
# List all workloads
kubectl get workloads -A

# Describe a workload
kubectl describe workload <workload-name>

# Check ClusterQueue usage
kubectl get clusterqueue -o wide
```

## Troubleshooting

### Webhook Not Ready

If jobs fail with webhook errors, the CA patcher may not have completed:

```bash
# Check CA patcher pod
kubectl get pods -n <namespace> -l app.kubernetes.io/component=ca-patcher

# Manually restart the controller if needed
kubectl rollout restart deployment/<release>-kueue-controller-controller-manager -n <namespace>
```

### Workloads Stuck in Pending

Check ClusterQueue status and available resources:

```bash
kubectl get clusterqueue -o yaml
kubectl describe workload <workload-name>
```

## References

- [Kueue Documentation](https://kueue.sigs.k8s.io/docs)
- [WaitForPodsReady Setup](https://kueue.sigs.k8s.io/docs/tasks/manage/setup_wait_for_pods_ready/)
- [Object Retention Policy](https://kueue.sigs.k8s.io/docs/tasks/manage/setup_object_retention_policy/)
- [Running Kubernetes Jobs](https://kueue.sigs.k8s.io/docs/tasks/run/jobs/)
