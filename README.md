# Prometheus Exporter Operator

<img src="img/prometheus-exporter-operator-logo.svg" height="150px" alt="Prometheus Exporter Operator"></img>

[![build status](https://circleci.com/gh/3scale/prometheus-exporter-operator.svg?style=shield)](https://circleci.com/gh/3scale/prometheus-exporter-operator)
[![release](https://badgen.net/github/release/3scale/prometheus-exporter-operator)](https://github.com/3scale/prometheus-exporter-operator/releases)
[![license](https://badgen.net/github/license/3scale/prometheus-exporter-operator)](https://github.com/3scale/prometheus-exporter-operator/blob/master/LICENSE)

A Kubernetes Operator based on the Operator SDK to centralize the setup of 3rd party prometheus exporters on **Kubernetes/OpenShift**, with a collection of grafana dashboards.

You can setup different prometheus exporters to monitor the internals from different databases, or even any available cloudwatch metric from any AWS Service, by just providing a few parameters like *dbHost* or *dbPort* (operator manage the container image, port, argument, command, volumes... and also prometheus `ServiceMonitor` and `GrafanaDashboard` k8s objects).

Current prometheus exporters `types` supported, managed by same prometheus-exporter-operator:
* memcached
* redis
* mysql
* postgresql
* sphinx
* es (elasticsearch)
* cloudwatch
* probe (blackbox)

The operator manages the lifecycle of the following objects:
* Deployment (one per CR)
* Service (one per CR)
* ServiceMonitor (optional, one per CR)
* GrafanaDashboard (optional, one per Namespace)

> **NOTE**
><br /> Some exporters need some **extra objects to be previously manually created** in order to work (**manual objects names need to be specified on required CR fields**). This extra needed objects includes **Secrets (credentials) or Configmaps (configuration files) on specific formats**. Examples to help you create these extra objects are provided on [examples](examples/) directory for all exporter types.
><br />
><br /> **If you modify the content of these extra needed objects (*Secrets*/*Configmaps*), exporters won't load them automatically, so you need to force a new pod creation by for example deleting the running pod.**

## Current status

Operator is available at [OperatorHub.io](https://operatorhub.io/operator/prometheus-exporter-operator) (on both Kubernetes/OpenShift OLM catalogs)

## Requirements

* [prometheus-operator](https://github.com/coreos/prometheus-operator) v0.17.0+
* [grafana-operator](https://github.com/integr8ly/grafana-operator) v3.0.0+

## Documentation

* [Getting started](docs/getting-started.md)
* [Examples](examples/)
* [PrometheusExporter Custom Resource Reference](docs/prometheus-exporter-crd-reference.md)

## GrafanaDashboards

`GrafanaDashboards` management is included in the operator:
* For each CR, a `GrafanaDashboard` (optional, enabled by default `grafanaDashboard.enabled: true`) is created, but actually operator manages a single dashboard type per Namespace (not per CR)
* If you deploy for example different redis CRs, and you want to have the redis dashboard created, you need to enabled it on every redis CR with the same grafana-operator label selector (but actually, operator will just manage a single dashboard per Namespace shared accross all CRs from the same type)
* You can deploy the prometheus-exporter-operator with different operator versions on different Namespaces, so operator will create separate dashboards per Namespace (they won't collision, that's why dashboard name includes the Namespace)
* All grafana dashboards are preconfigured to use `CR_NAME` as the filter of all possible dashboards of every type (for example `staging-system-memcached`)
* *In the future it is possible that `GrafanaDashboard` management get its own CRD separate from `PrometheusExporter` CRD (so you could have N PrometheusExporter CRs, and also an additonal single Dashboard CR per exporter type*

### Memcached example dashboard
<img src="img/example-memcached-dashboard.png" height="250px" alt="Example Memcached Dashboard"></img>

### Redis example dashboard
<img src="img/example-redis-dashboard.png" height="250px" alt="Example Redis Dashboard"></img>

### MySQL example dashboard
<img src="img/example-mysql-dashboard.png" height="250px" alt="Example MySQL Dashboard"></img>

### PostgreSQL example dashboard
<img src="img/example-postgresql-dashboard.png" height="250px" alt="Example PostgreSQL Dashboard"></img>

### Sphinx example dashboard
<img src="img/example-sphinx-dashboard.png" height="250px" alt="Example Sphinx Dashboard"></img>

### Elasticsearch example dashboard
<img src="img/example-es-dashboard.png" height="250px" alt="Example Elasticsearch Dashboard"></img>

### AWS CloudWatch example dashboard
<img src="img/example-cloudwatch-dashboard.png" height="250px" alt="Example AWS Cloudwatch Dashboard"></img>

### Blackbox probe example dashboard
<img src="img/example-probe-dashboard.png" height="250px" alt="Example Blackbox Probe Dashboard"></img>

## PrometheusRules

`PrometheusRules` management is NOT included in the operator (at least by the moment), because it depends on:
* What you need to monitor (maybe ones just need basic cpu/mem alerts, while others may be interested on specific alerts checking internals of a database)
* Why you want to be paged (severity warning/critical, minutes duration before firing an alert...)
* Customizable thresholds definition (it is something that depends on infrastructure dimensions...)

However, some examples of prometheus rules can be found on [prometheus-rules](prometheus-rules/) directory.
* Deploy all `PrometheusRules` examples:
```bash
$ make prometheus-rules-deploy
```
* Once tested, delete deployed rules:
```bash
$ make prometheus-rules-delete
```

## Development

To run the operator locally you need to install some ansible dependencies first:

* ansible-runner: `sudo dnf install python-ansible-runner`
* ansible-runner-http: `pip install python-ansible-runner`
* openshift ansible module: `pip install openshift`

You can then run the operator with the following command:

```bash
operator-sdk run --local --watch-namespace <namespace>
```

## Release

1. Update Makefile variable `VERSION` to the appropiate release version.
1. If it is an **alpha** release, execute make target `make prepare-alpha-release`
1. If it is an **stable** release, execute make target `make prepare-release`
1. Open a [Pull Request](https://github.com/3scale/prometheus-exporter-operator/pulls)

## Contributing

You can contribute by:

* Raising any issues you find using Prometheus Exporter Operator
* Fixing issues by opening [Pull Requests](https://github.com/3scale/prometheus-exporter-operator/pulls)
* Submitting a patch or opening a PR
* Improving documentation
* Talking about Prometheus Exporter Operator

All bugs, tasks or enhancements are tracked as [GitHub issues](https://github.com/3scale/prometheus-exporter-operator/issues).

## License

Prometheus Exporter Operator is under Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
