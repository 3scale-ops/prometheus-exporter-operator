# Prometheus Exporter Examples

Once the deployed prometheus-exporter operator is up and running and watching for any `PrometheusExporter` resource type, you can setup any prometheus exporter following the next examples:

1. [Memcached](#memcached)
1. [Redis](#redis)
1. [MySQL](#mysql)
1. [PostgreSQL](#postgresql)
1. [Sphinx](#sphinx)
1. [Elasticsearch](#elasticsearch)
1. [AWS CloudWatch](#aws-cloudwatch)
1. [Probe](#probe)

## Memcached

* Official doc: https://github.com/prometheus/memcached_exporter

### Deploy example
* Create `memcached-exporter` example ([example-DB](memcached/memcached-db-service.yaml), [example-CR](memcached/memcached-cr.yaml)):
```bash
$ make memcached-create
```
* Once tested, delete created objects:
```bash
$ make memcached-delete
```

## Redis

* Official doc: https://github.com/oliver006/redis_exporter

### Deploy example

* Create `redis-exporter` example ([example-DB](redis/redis-db-service.yaml), [example-CR](redis/redis-cr.yaml), [example-CR-2](redis/redis-cr-2.yaml)):
```bash
$ make redis-create
```
* Once tested, delete created objects:
```bash
$ make redis-delete
```

## MySQL

* Official doc: https://github.com/prometheus/mysqld_exporter

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

## PostgreSQL

* Official doc: https://github.com/wrouesnel/postgres_exporter

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

## Sphinx

* Official doc: https://github.com/foxdalas/sphinx_exporter

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

## Elasticsearch

* Official doc: https://github.com/justwatchcom/elasticsearch_exporter

### Deploy example

* **Make sure you have an Elasticsearch cluster available and that dbHost/dbPort are correctly set on CR example file**
* Create `elasticsearch-exporter` example ([example-CR](elasticsearch/es-cr.yaml)):
```bash
$ make elasticsearch-create
```
* Once tested, delete created objects:
```bash
$ make elasticsearch-delete
```

## AWS CloudWatch

* Official doc: https://github.com/prometheus/cloudwatch_exporter
> **NOTE**
><br /> The metrics from some services like `AWSClientVPN` are reported to AWS CloudWatch every **5 minutes** (instead of default **1 minute**), because they are not critical services like databases (RDS/EC) where details are more important. So on thoses cases, scrapping AWS Cloudwatch metrics every 1 minute makes no sense, so it is better to specify the var `period_seconds: 300` (instead of default `period_seconds: 60`) in the metric definition in the configmap. In addition, for those cases reporting metrics every 5 minutes, empty spaces (null values) could appear empty in the prometheus time series database, so in order to configure alerts, you can use queries like `max_over_time(aws_clientvpn_crl_days_to_expiry_average[10m]) < 2`, which takes max value within last 10 minutes, so we guarantee there is always a value that can fire an alert that won't disappear from time to time although alert might not be really recovered.

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

## Probe

* Official doc: https://github.com/prometheus/blackbox_exporter

### CR needed extra object

* **The ConfigMap should have been previously created as the operator expects it**:
  * **[probe-configmap-example](probe/probe-configmap.yaml) (Remember to set the object name on the CR field `configurationConfigmapName`)**
* **The optional Secret (replacing previous ConfigMap) should have been previously created as the operator expects it (in case config includes sensitive data and so you prefer to use a Secret**
  * **[probe-secret-example](probe/probe-secret.yaml) (Remember to set the object name on the CR field `configurationSecretName` replacing previous `configurationConfigmapName`)**

> **NOTE**
><br /> To deploy a probe exporter (blackbox exporter) it is just needed the configmap (or secret) with blackbox modules configuration, and a single `PrometheusExporter` custom resource of type `probe`. But then, in order to be able to scrape different targets, you need to deploy for every endpoint that you want to monitor, a prometheus `ServiceMonitor` resource with the `selector.matchLabels` pointing to the deployed probe exporter `app: prometheus-exporter-probe-${CR_NAME}`, and then configure the specific module and target, with a proper relabeling of source label `__param_target` into target label `target` (which is used in the deployed grafana dashboard and possible prometheus alerts).

### Target ServiceMonitor extra objects
  * **[probe-target-service-monitor-example](probe/probe-target-service-monitor.yaml) (Remember to set the `selector.matchLabels` pointing to the deployed probe exporter `app: prometheus-exporter-probe-${CR_NAME}`)**

### Deploy example

* Create `probe-exporter` example ([example-configmap](probe/probe-configmap.yaml), [example-CR](probe/probe-cr.yaml), [example-target-service-monitor](probe/probe-target-service-monitor.yaml)):
```bash
$ make probe-create
```
* Once tested, delete the created objects:
```bash
$ make probe-delete
```