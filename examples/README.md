# Prometheus-exporter examples

Once the deployed prometheus-exporter operator is up and running and watching for any `PrometheusExporter` resource type, you can setup any prometheus exporter following the next examples:

1. [Memcached prometheus-exporter](#memcached-prometheus-exporter)
1. [Redis prometheus-exporter](#redis-prometheus-exporter)
1. [MySQL prometheus-exporter](#mysql-prometheus-exporter)
1. [PostgreSQL prometheus-exporter](#postgresql-prometheus-exporter)
1. [Sphinx prometheus-exporter](#sphinx-prometheus-exporter)
1. [ElasticSearch prometheus-exporter](#elasticsearch-prometheus-exporter)
1. [AWS CloudWatch prometheus-exporter](#aws-cloudwatch-prometheus-exporter)

## Memcached prometheus-exporter

* Official doc: https://github.com/prometheus/memcached_exporter

### CR Spec custom

| **Field** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|
| `dbHost` | Yes | `system-memcache` | Memcached Host (could be a k8s service or any internal/external DNS endpoint) |
| `dbPort` | Yes | `11211` | Memcached Port |

### Deploy example
* Create `memcached-exporter` example ([example-DB](memcached/memcached-db-service.yaml), [example-CR](memcached/memcached-cr.yaml)):
```bash
$ make memcached-create
```
* Once tested, delete created objects:
```bash
$ make memcached-delete
```

## Redis prometheus exporter

* Official doc: https://github.com/oliver006/redis_exporter

### CR Spec custom

| **Field** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|
| `dbHost` | Yes | `backend-redis` | Redis Host (could be a k8s service or any internal/external DNS endpoint) |
| `dbPort` | Yes | `6379` | Redis Port |
| `dbCheckKeys` | No | - | Redis specific keys to check |

### Deploy example

* Create `redis-exporter` example ([example-DB](redis/redis-db-service.yaml), [example-CR](redis/redis-cr.yaml), [example-CR-2](redis/redis-cr-2.yaml)):
```bash
$ make redis-create
```
* Once tested, delete created objects:
```bash
$ make redis-delete
```

## MySQL prometheus exporter

* Official doc: https://github.com/prometheus/mysqld_exporter

### CR Spec custom

| **Field** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|
| `dbConnectionStringSecretName` | Yes | `prometheus-exporter-mysql-${CR_NAME}` | Secret name containing MySQL connection string definition (`DATA_SOURCE_NAME`) |

### CR needed extra object

* **The Secret should have been previously created as the operator expects it**:
  * **[mysql-secret-example](mysql/mysql-secret.yaml) (Remember to set object name on CR field `dbConnectionStringSecretName`)**

### Permission requirements

* In addition, a database user with specific grants is needed *(this is just an example, go to the official doc for the latest information)*:

```sql
CREATE USER 'exporter'@'%' IDENTIFIED BY 'XXXXXXXX' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
```

> **NOTE**
> <br /> It is recommended to set a max connection limit for the user to avoid overloading the server with monitoring scrapes under heavy load.

### Deploy example

* Create `mysql-exporter` example ([example-secret](mysql/mysql-secret.yaml), [example-DB](mysql/mysql-db-service.yaml), [example-CR](mysql/mysql-cr.yaml)):
```bash
$ make mysql-create
```
* Once tested, delete created objects:
```bash
$ make mysql-delete
```

## PostgreSQL prometheus exporter

* Official doc: https://github.com/wrouesnel/postgres_exporter

### CR Spec custom

| **Field** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|
| `dbConnectionStringSecretName` | Yes | `prometheus-exporter-postgresql-${CR_NAME}` | Secret name containing PostgreSQL connection string definition (`DATA_SOURCE_NAME`) |

### CR needed extra object

* **The Secret should have been previously created as the operator expects it**:
  * **[postgresql-secret-example](postgresql/postgresql-secret.yaml) (Remember to set the object name on the CR field `dbConnectionStringSecretName`)**

### Permission requirements

* In addition, a database user with specific grants is needed*(this is just an example, go to official doc for latest information)*. To be able to collect metrics from `pg_stat_activity` and `pg_stat_replication` as `non-superuser` you have to create views as a `superuser`, and assign permissions separately to those. In PostgreSQL, views run with the permissions of the user that created them so they can act as security barriers *(this is just an example, go to official doc for latest information)*:

```sql
CREATE USER postgres_exporter PASSWORD 'password';
ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;

-- If deploying as non-superuser (for example in AWS RDS), uncomment the GRANT
-- line below and replace <MASTER_USER> with your root user.
-- GRANT postgres_exporter TO <MASTER_USER>
CREATE SCHEMA postgres_exporter AUTHORIZATION postgres_exporter;

CREATE VIEW postgres_exporter.pg_stat_activity
AS
  SELECT * from pg_catalog.pg_stat_activity;

GRANT SELECT ON postgres_exporter.pg_stat_activity TO postgres_exporter;

CREATE VIEW postgres_exporter.pg_stat_replication AS
  SELECT * from pg_catalog.pg_stat_replication;

GRANT SELECT ON postgres_exporter.pg_stat_replication TO postgres_exporter;
```

> **NOTE**
> <br />Remember to use `postgres` database name in the connection string:
> ```
> DATA_SOURCE_NAME=postgresql://postgres_exporter:password@localhost:5432/postgres?sslmode=disable
> ```

### Deploy example

* Create `postgresql-exporter` example ([example-secret](postgresql/postgresql-secret.yaml), [example-DB](postgresql/postgresql-db-service.yaml), [example-CR](postgresql/postgresql-cr.yaml)):
```bash
$ make postgresql-create
```
* Once tested, delete created objects:
```bash
$ make postgresql-delete
```

## Sphinx prometheus exporter

* Official doc: https://github.com/foxdalas/sphinx_exporter

### CR Spec custom

| **Field** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|
| `dbHost` | Yes | `system-sphinx` | Sphinx Host (could be k8s service or any internal/external DNS endpoint) |
| `dbPort` | Yes | `9306` | Sphinx Port |

### Deploy example

* **Make sure you have a Sphinx instance available, and dbHost/dbPort are correctly set on CR example file**
* Create `sphinx-exporter` example ([example-CR](sphinx/sphinx-cr.yaml)):
```bash
$ make sphinx-create
```
* Once tested, delete created objects:
```bash
$ make sphinx-delete
```

## ElasticSearch prometheus exporter

* Official doc: https://github.com/braedon/prometheus-es-exporter

### CR Spec custom

| **Field** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|
| `dbHost` | Yes | `http://logging-es.openshift-logging.svc` | Elasticsearch Host (could be k8s service or any internal/external DNS endpoint) |
| `dbPort` | Yes | `9200` | Elasticsearch  Port |
| `configurationConfigmapName` | Yes | `prometheus-exporter-elasticsearch-${CR_NAME}` | ConfigMap name containing ElasticSearch `es_exporter.cfg` with defined queries to run |

### CR needed extra object

* **The ConfigMap should have been previously created as the operator expects it**:
  * **[es-configmap-example](elasticsearch/elasticsearch-configmap.yaml) (Remember to set the object name on the CR field `configurationConfigmapName`)**

### Deploy example

* **Make sure you have an ElasticSearch cluster available and that dbHost/dbPort are correctly set on CR example file**
* Create `elasticsearch-exporter` example ([example-configmap](elasticsearch/elasticsearch-configmap.yaml), [example-CR](elasticsearch/elasticsearch-cr.yaml)):
```bash
$ make elasticsearch-create
```
* Once tested, delete created objects:
```bash
$ make elasticsearch-delete
```

## AWS CloudWatch prometheus exporter

* Official doc: https://github.com/prometheus/cloudwatch_exporter

### CR Spec custom

| **Field** | **Required** | **Default value** | **Description** |
|:---:|:---:|:---:|:---:|
| `awsCredentialsSecretName` | Yes | `prometheus-exporter-cloudwatch-${CR_NAME}` | Secret name containing AWS IAM credentials (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) |
| `configurationConfigmapName` | Yes | `prometheus-exporter-cloudwatch-${CR_NAME}` | ConfigMap name containing Cloudwatch `config.yml` (Services, Dimensions, Tags used for autodiscovery...) |

### CR needed extra objects

* **The Secret/ConfigMap should have been previously created as the operator expects them**:
  * **[cw-secret-example](cloudwatch/cloudwatch-secret.yaml) (Remember to set the object name on the CR field `awsCredentialsSecretName`)**
  * **[cw-configmap-example](cloudwatch/cloudwatch-configmap.yaml) (Remember to set the object name on the CR field `configurationConfigmapName`)**

### Permission requirements

* In addition, the created IAM user requires some specific IAM permissions:
  * `cloudwatch:ListMetrics`
  * `cloudwatch:GetMetricStatistics`
  * `tag:GetResources`

### Deploy example

* Create `cloudwatch-exporter` example ([example-secret](cloudwatch/cloudwatch-secret.yaml), [example-configmap](cloudwatch/cloudwatch-configmap.yaml), [example-CR](cloudwatch/cloudwatch-cr.yaml)):
```bash
$ make cloudwatch-create
```
* Once tested, delete the created objects:
```bash
$ make cloudwatch-delete
```
