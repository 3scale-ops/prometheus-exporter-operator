# Prometheus Exporter Custom Resource Reference

## Full CR Example

Most of the fields do not need to be specified (can use default values), this is just an example of everything that can be overriden under your own risk:

```yaml
apiVersion: monitoring.3scale.net/v1alpha1
kind: PrometheusExporter
metadata:
  name: staging-system-memcached
spec:
  type: memcached
  serviceMonitor:
    enabled: true
    interval: 45s
  grafanaDashboard:
    enabled: true
    label:
      key: monitoring-key
      value: middleware
  extraLabel:
    key: tier
    value: frontend
  dbHost: system-memcache
  dbPort: 11211
  image:
    name: prom/memcached-exporter
    version: v0.6.0
  port: 9150
  livenessProbe:
    timeoutSeconds: 10
    periodSeconds: 20
    successThreshold: 1
    failureThreshold: 7
  readinessProbe:
    timeoutSeconds: 10
    periodSeconds: 20
    successThreshold: 1
    failureThreshold: 7
  nodeSelector:
    node: test
  resources:
    requests:
      cpu: 75m
      memory: 64Mi
    limits:
      cpu: 150m
      memory: 128Mi
```

## CR Spec Common

| **Field** | **Type** | **Required** | **Default value (some depends on type)** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `type` | `string` | Yes | `none` | Supported prometheus-exporter types: `memcached`, `redis`, `mysql`, `postgresql`, `sphinx`, `es`, `cloudwatch`, `probe` |
| `serviceMonitor.enabled` | `bool` | No | `true` | Create (`true`) or not (`false`) ServiceMonitor object |
| `serviceMonitor.interval` | `string` | No | `30s` | Prometheus scrape interval |
| `grafanaDashboard.enabled` | `bool` | No | `true` | Create (`true`) or not (`false`) GrafanaDashboard object |
| `grafanaDashboard.label.key` | `string` | No | discovery | Label `key` used by grafana-operator for dashboard discovery |
| `grafanaDashboard.label.value` | `string` | No | enabled | Label `value` used by grafana-operator for dashboard discovery |
| `extraLabel.key` | `string` | No | - | Add extra label `key` to all created resources (example `tier`) |
| `extraLabel.value` | `string` | No | - | Add extra label `value` to all created resources (example `frontend`) |
| `image.name` | `string` | No | Depends on exporter | Prometheus exporter image name |
| `image.version` | `string` | No | Depends on exporter | Prometheus exporter image tag version |
| `port` | `int` | No | Depends on exporter | Prometheus exporter metrics port |
| `resources.requests.cpu` | - | No | `25m` | Override CPU requests |
| `resources.requests.memory` | - | No | `32Mi` | Override Memory requests |
| `resources.limits.cpu` | - | No | `50m` | Override CPU limits |
| `resources.limits.memory` | - | No | `64Mi` | Override Memory limits |
| `livenessProbe.timeoutSeconds` | `int` | No | `3` | Override liveness timeout (seconds) |
| `livenessProbe.periodSeconds` | `int` | No | `15` | Override liveness period (seconds) |
| `livenessProbe.successThreshold` | `int` | No | `1` | Override liveness success threshold |
| `livenessProbe.failureThreshold` | `int` | No | `5` | Override liveness failure threshold |
| `readinessProbe.timeoutSeconds` | `int` | No | `3` | Override readiness timeout (seconds) |
| `readinessProbe.periodSeconds` | `int` | No | `30` | Override readiness period (seconds) |
| `readinessProbe.successThreshold` | `int` | No | `1` | Override readiness success threshold |
| `readinessProbe.failureThreshold` | `int` | No | `5` | Override readiness failure threshold |
| `nodeSelector` | `map` | No | - | Map of nodeSelector key-value pairs |

## CR Spec Custom

Specific CR fields per exporter type:

### CR Spec Custom Type Memcached

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `dbHost` | `string`| Yes | `system-memcache` | Memcached Host (could be a k8s service or any internal/external DNS endpoint) |
| `dbPort` | `int`| Yes | `11211` | Memcached Port |

* Image, port, resources, liveness, readiness default values can be found at [ansible-memcached-vars](../roles/prometheusexporter/vars/memcached.yml)
* Real `memcached` example can be found on [examples](../examples/README.md#memcached) directory.

### CR Spec Custom Type Redis

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `dbHost` | `string` | Yes | `backend-redis` | Redis Host (could be a k8s service or any internal/external DNS endpoint) |
| `dbPort` | `int`| Yes | `6379` | Redis Port |
| `dbCheckKeys` | `string`| No | - | Optional redis specific keys to check |

* Image, port, resources, liveness, readiness default values can be found at [ansible-redis-vars](../roles/prometheusexporter/vars/redis.yml)
* Real `redis` example can be found on [examples](../examples/README.md#redis) directory.

### CR Spec Custom Type MySQL

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `dbConnectionStringSecretName` | `string` | Yes | `prometheus-exporter-mysql-${CR_NAME}` | Secret name containing MySQL connection string definition (`DATA_SOURCE_NAME`) |

* Image, port, resources, liveness, readiness default values can be found at [ansible-mysql-vars](../roles/prometheusexporter/vars/mysql.yml)
* Real `mysql` example can be found on [examples](../examples/README.md#mysql) directory.

### CR Spec Custom Type PostgreSQL

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `dbConnectionStringSecretName` | `string` | Yes | `prometheus-exporter-postgresql-${CR_NAME}` | Secret name containing PostgreSQL connection string definition (`DATA_SOURCE_NAME`) |

* Image, port, resources, liveness, readiness default values can be found at [ansible-postgresql-vars](../roles/prometheusexporter/vars/postgresql.yml)
* Real `postgresql` example can be found on [examples](../examples/README.md#postgresql) directory.

### CR Spec Custom Type Sphinx

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `dbHost` | `string`| Yes | `system-sphinx` | Sphinx Host (could be k8s service or any internal/external DNS endpoint) |
| `dbPort` | `int`| Yes | `9306` | Sphinx Port |

* Image, port, resources, liveness, readiness default values can be found at [ansible-sphinx-vars](../roles/prometheusexporter/vars/sphinx.yml)
* Real `sphinx` example can be found on [examples](../examples/README.md#sphinx) directory.

### CR Spec Custom Type Es (Elasticsearch)

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `dbHost` | `string`| Yes | `http://elasticsearch` | Elasticsearch Host (could be k8s service or any internal/external DNS endpoint) |
| `dbPort` | `int`| Yes | `9200` | Elasticsearch Port |

* Image, port, resources, liveness, readiness default values can be found at [ansible-es-vars](../roles/prometheusexporter/vars/es.yml)

* Real `es` example can be found on [examples](../examples/README.md#elasticsearch) directory.

### CR Spec Custom Type CloudWatch

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `awsCredentialsSecretName` | `string` | Yes | `prometheus-exporter-cloudwatch-${CR_NAME}` | Secret name containing AWS IAM credentials (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) |
| `configurationConfigmapName` | `string` | Yes | `prometheus-exporter-cloudwatch-${CR_NAME}` | ConfigMap name containing Cloudwatch `config.yml` (Services, Dimensions, Tags used for autodiscovery...) |

* Image, port, resources, liveness, readiness default values can be found at [ansible-cloudwatch-vars](../roles/prometheusexporter/vars/cloudwatch.yml)
* Real `cloudwatch` example can be found on [examples](../examples/README.md#aws-cloudwatch) directory.

### CR Spec Custom Type Probe

| **Field** | **Type** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|:---:|
| `configurationConfigmapName` | `string` | Yes | `prometheus-exporter-probe-${CR_NAME}` | ConfigMap name containing blackbox modules configuration `config.yml` (http_2xx, tcp_connect...) |

* Image, port, resources, liveness, readiness default values can be found at [ansible-probe-vars](../roles/prometheusexporter/vars/probe.yml)
* Real `probe` example can be found on [examples](../examples/README.md#probe) directory.