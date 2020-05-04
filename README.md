# Prometheus-exporter Operator

A Kubernetes Operator based on the Operator SDK (`ansible` version) to centralize the setup of 3rd party prometheus exporters on **Kubernetes/OpenShift**.

Current prometheus exporters `types` supported, managed by same prometheus-exporter operator:
* memcached
* redis
* mysql
* postgresql
* sphinx
* elasticsearch
* cloudwatch

The operator manages, for each CR, the lifecycle of the following objects:
* Deployment
* Service
* ServiceMonitor (optional using `serviceMonitorState: "present"`)

> **NOTE**
><br /> Some exporters need some **extra objects to be previously manually created** in order to work (**manual objects names need to be specified on required CR fields**). This extra needed objects includes **Secrets (credentials) or Configmaps (configuration files) on specific formats**. Examples to help you create these extra objects are provided on [examples](examples/) directory for all exporter types.

## Requirements

* [Kubernetes](https://kubernetes.io) v1.11.0+ or [OpenShift](https://www.openshift.com) v3.11.0+
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) v1.9.0+ or [oc](https://docs.okd.io/latest/cli_reference/get_started_cli.html#cli-reference-get-started-cli) v1.11.0+
* [operator-sdk](https://github.com/operator-framework/operator-sdk) v0.13.0+
* [application-monitoring-operator](https://github.com/integr8ly/application-monitoring-operator) (including Prometheus, Alertmanager and Grafana) v1.0.0+

## Getting Started

### Operator image

* Apply changes on Operator ([ansible role](roles/prometheusexporter/)), then create a new operator image and push it to the registry with:
```bash
$ make operator-image-update
```
* Operator images are available [here](https://quay.io/repository/3scale/prometheus-exporter-operator?tab=tags)

### Operator deploy

* Deploy operator (Namespace, CRD, operator objects):
```bash
$ make operator-create
```
* Create any `PrometheusExporter` resource type (you can find examples on [examples](examples/) directory).
* Once tested, delete created operator objects (except CRD/Namespace for caution):
```bash
$ make operator-delete
```

## PrometheusExporter CustomResource

### CR Example

```
apiVersion: ops.3scale.net/v1alpha1
kind: PrometheusExporter
metadata:
  name: redis-staging
spec:
  type: "redis"
  serviceMonitorState: "present"
  labelCustomKey: "tier"
  labelCustomValue: "backend"
  dbHost: "redis-service"
  dbPort: "6379"
  resourcesLimitsCpu: "75m"
  resourcesLimitsMemory: "128Mi"
  livenessProbeTimeoutSeconds: 4
  readinessProbeTimeoutSeconds: 5
```

### CR Spec common

| **Field** | **Type** | **Required** | **Default value (depends on type)** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `type` | `string` | Yes | `none` | Possible prometheus-exporter types: `memcached`, `redis`, `mysql`, `postgresql`, `sphinx`, `elasticsearch`, `cloudwatch` |
| `serviceMonitorState` | `string` | No | `absent` | Create (`present`) or not (`absent`) ServiceMonitor object |
| `labelCustomKey` | `string` | No | - | Add extra label `key` to all created resources (example `tier`) |
| `labelCustomValue` | `string` | No | - | Add extra label `value` to all created resources (example `backend`) |
| `resourcesRequestsCpu` | `string` | No | `25m` | Override CPU requests |
| `resourcesRequestsMemory` | `string` | No | `32Mi` | Override Memory requests |
| `resourcesLimitsCpu` | `string` | No | `50m` | Override CPU limits |
| `resourcesLimitsMemory` | `string` | No | `64Mi` | Override Memory limits |
| `livenessProbeTimeoutSeconds` | `int` | No | `3` | Override liveness timeout (seconds) |
| `livenessProbePeriodSeconds` | `int` | No | `15` | Override liveness period (seconds) |
| `livenessProbeSuccessThreshold` | `int` | No | `1` | Override liveness success threshold |
| `livenessProbeFailureThreshold` | `int` | No | `5` | Override liveness failure threshold |
| `readinessProbeTimeoutSeconds` | `int` | No | `3` | Override readiness timeout (seconds) |
| `readinessProbePeriodSeconds` | `int` | No | `30` | Override readiness period (seconds) |
| `readinessProbeSuccessThreshold` | `int` | No | `1` | Override readiness success threshold |
| `readinessProbeFailureThreshold` | `int` | No | `5` | Override readiness failure threshold |

### CR Spec custom

Specific CR fields per exporter type, extra objects needed, database permissions... can be found on [examples](examples/) directory.

## Grafana Dashboards

* Some examples of grafana dashboards can be found on [grafana-dashboards](grafana-dashboards/) directory.
* All grafana dashboards are preconfigured to use `CR_NAME` as the filter of all possible dashboards of every type (for example `bakend-redis-staging`).
* Create all example Grafana Dashboards (Memcached, Redis, MySQL, PostgreSQL, Sphinx):
```bash
$ make grafana-dashboards-create:
```
* Once tested, delete created dashboards:
```bash
$ make grafana-dashboards-delete
```

## Prometheus Rules

* Some examples of prometheus rules can be found on [prometheus-rules](prometheus-rules/) directory. ***Take into account that alert thresholds depend on your monitored servers dimensions, so you may need to customize them.***
* Create all example Prometheus Rules (General, Memcached, Redis, MySQL, PostgreSQL, Sphinx):
```bash
$ make prometheus-rules-create:
```
* Once tested, delete created rules:
```bash
$ make prometheus-rules-delete
```

## License

Prometheus-exporter operator is under Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
