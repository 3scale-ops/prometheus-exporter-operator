# Install

## OperatorHub.io

* **The recommendd way to install the operator is to install it via OLM with the version published at [OperatorHub.io](https://operatorhub.io/operator/prometheus-exporter-operator) (on both Kubernetes/OpenShift OLM catalogs)**
* However, there are other options to install it using `kustomize` or `operator-sdk`

## Manual deploy
* To manually install the operator (on all its dependant resources) on default namespace `prometheus-exporter-operator-system` without using OLM, you can use the following make target (which uses `kustomize`):
```bash
$ make deploy
```
* Then create any `PrometheusExporter` resource type (you can find examples on [examples](../examples/) directory).
* Once tested, delete created operator resources using the following make target:
```bash
$ make undeploy
```

## OLM deploy
* If you want to install a specific version of the operator via OLM without using the version published at [OperatorHub.io](https://operatorhub.io/operator/prometheus-exporter-operator), you can use for example the following command:
```bash
operator-sdk run bundle quay.io/3scale/prometheus-exporter-operator-bundle:0.3.0-alpha.11 --namespace prom-exporter
```
* Then create any `PrometheusExporter` resource type (you can find examples on [examples](../examples/) directory).
* If for example you want to test an operator upgrade of a newer version, execute for example:
```bash
operator-sdk run bundle-upgrade quay.io/3scale/prometheus-exporter-operator-bundle:0.3.0-alpha.12 --namespace prom-exporter
```