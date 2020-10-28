# Getting Started

## Operator image

* Apply changes on Operator ([ansible role](../roles/prometheusexporter/)), then create a new operator image and push it to the registry with:
```bash
$ make operator-image-update
```
* Operator images are available [here](https://quay.io/repository/3scale/prometheus-exporter-operator?tab=tags)

## Operator deploy

### Local deploy
* Deploy operator locally for developmnt purpose without generating a new image:
```bash
$ make operator-local-deploy
```
* Create any `PrometheusExporter` resource type (you can find examples on [examples](../examples/) directory).

### Manual deploy
* Deploy operator (namespace, CRD, service account, role, role binding and operator deployment):
```bash
$ make operator-manual-deploy
```
* Create any `PrometheusExporter` resource type (you can find examples on [examples](../examples/) directory).
* Once tested, delete created operator objects (except CRD/namespace for caution):
```bash
$ make operator-manual-delete
```

### OLM deploy
* Deploy operator (namespace, operator source, operator group and operator subscription):
```bash
$ make operator-olm-deploy
```
* Create any `PrometheusExporter` resource type (you can find examples on [examples](../examples/) directory).
* Once tested, delete created operator objects (except namespace for caution):
```bash
$ make operator-olm-delete
```

## Operator OLM Manifests

### Manifests generate
* Generate Operator OLM CSV manifests for specific version using `operator-sdk` tool:
```bash
$ make manifests-generate
```

### Manifests verify
* Verify Operator OLM CSV manifests/package using `operator-courier` tool:
```bash
$ make manifests-verify
```

### Manifests push
* Before publishing a release on a given quay.io namespace, make sure everything is 100% correct, because releases cannot be deleted or overridden
* So before publishing a final release on `3scaleops` quay namespace, you can do tests on your own personal quay.io namespace (doing incremental release versions always for any test), and pushing final metadata to the appropiate release version on `3scaleops` namespace
* Push Operator OLM CSV manifests/package for specific version to Application Registry using `operator-courier` tool:
```bash
$ make manifests-push
```