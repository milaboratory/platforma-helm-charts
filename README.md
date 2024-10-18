[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/platforma)](https://artifacthub.io/packages/search?repo=platforma)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

Helm Charts
===========

This repository contains helm charts for Platforma

Current applications
--------------------

- [Platforma](charts/platforma)

## Add a chart helm repository

Access a Kubernetes cluster.

Add a chart helm repository with follow commands:

```console
helm repo add platforma https://milaboratory.github.io/platforma-helm-charts

helm repo update
```

## Installing the chart

Export default values of `platforma` chart to file `values.yaml`:

```console
helm show values platforma/platforma > values.yaml
```

Change the values according to the need of the environment in ``values.yaml`` file.

Test the installation with command:

```console
helm install pl0 platforma/platforma -f values.yaml -n NAMESPACE --debug --dry-run
```

Install chart with command:

```console
helm install pl0 platforma/platforma -f values.yaml -n NAMESPACE
```

## Validate installation

Get the pods lists by running these commands:

```console
kubectl get pods -A | grep 'platforma'

# or list all resorces of platforma

kubectl get all -n NAMESPACE | grep platforma
```

Get the application by running this commands:

```console
helm list -f pl0 -n NAMESPACE
```

See the history of versions of ``platforma`` application with command.

```console
helm history pl0 -n NAMESPACE
```

## How to uninstall Platforma

Remove application with command.

```console
helm uninstall pl0 -n NAMESPACE
```

## Kubernetes compatibility versions

helm charts tested at kubernetes versions from 1.28 to 1.30.
