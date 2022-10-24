.PHONY: help all clean

.DEFAULT_GOAL := help

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THISDIR_PATH := $(patsubst %/,%,$(abspath $(dir $(MKFILE_PATH))))

KUBE_CLIENT ?= kubectl # It can be used "oc" or "kubectl"
NAMESPACE ?= prometheus-exporter-operator-system

## General ##

all: memcached-create redis-create mysql-create postgresql-create sphinx-create elasticsearch-create cloudwatch-create probe-create sendgrid-create ## GENERAL - Create all examples

clean: memcached-delete redis-delete mysql-delete postgresql-delete sphinx-delete elasticsearch-delete cloudwatch-delete probe-delete sendgrid-delete ## GENERAL - Delete all examples

## Memcached ##

memcached-create: ## MEMCACHED EXAMPLE - Create: CR-DB, CR
	$(KUBE_CLIENT) apply -f memcached/ --validate=false -n $(NAMESPACE)

memcached-delete: ## MEMCACHED EXAMPLE - Delete: CR, CR-DB
	$(KUBE_CLIENT) delete -f memcached/ -n $(NAMESPACE) || true

## Redis ##

redis-create: ## REDIS EXAMPLES - Create: CR-DB, CR, CR-2
	$(KUBE_CLIENT) apply -f redis/ --validate=false -n $(NAMESPACE)

redis-delete: ## REDIS EXAMPLES - Delete: CR, CR-2, CR-DB
	$(KUBE_CLIENT) delete -f redis/ -n $(NAMESPACE) || true

## MySQL ##

mysql-create: ## MYSQL EXAMPLE - Create: CR-secret (connection string), CR-DB (with specific grants), CR
	$(KUBE_CLIENT) apply -f mysql/ --validate=false -n $(NAMESPACE)
	sleep 30
	$(KUBE_CLIENT) wait --timeout=180s --for condition=ready pod mysql-server-0 -n $(NAMESPACE)
	$(KUBE_CLIENT) exec mysql-server-0 -n $(NAMESPACE) -- mysql -u root -h localhost -e "CREATE USER 'exporter'@'%' IDENTIFIED BY '123456789';"
	$(KUBE_CLIENT) exec mysql-server-0 -n $(NAMESPACE) -- mysql -u root -h localhost -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';"

mysql-delete: ## MYSQL EXAMPLE - Delete: CR, CR-DB, CR-secret
	$(KUBE_CLIENT) delete -f mysql/ -n $(NAMESPACE) || true

## PostgreSQL ##

postgresql-create: ## POSTGRESQL EXAMPLE - Create: CR-secret (connection string), CR-DB, CR
	$(KUBE_CLIENT) apply -f postgresql/ --validate=false -n $(NAMESPACE)

postgresql-delete: ## POSTGRESQL EXAMPLE - Delete: CR, CR-DB, CR-secret
	$(KUBE_CLIENT) delete -f postgresql/ -n $(NAMESPACE) || true

## Sphinx ##

sphinx-create: ## SPHINX EXAMPLE - Create: CR (you need to provide a sphinx instance in advance)
	$(KUBE_CLIENT) apply -f sphinx/ --validate=false -n $(NAMESPACE)

sphinx-delete: ## SPHINX EXAMPLE - Delete: CR
	$(KUBE_CLIENT) delete -f sphinx/ -n $(NAMESPACE) || true

## Elasticsearch ##

elasticsearch-create:  ## ELASTICSEARCH EXAMPLE - Create: CR (you need to provide a ES cluster in advance)
	$(KUBE_CLIENT) apply -f elasticsearch/ --validate=false -n $(NAMESPACE)

elasticsearch-delete: ## ELASTICSEARCH EXAMPLE - Delete: CR
	$(KUBE_CLIENT) delete -f elasticsearch/ -n $(NAMESPACE) || true

## CloudWatch ##

cloudwatch-create: ## CLOUDWATCH EXAMPLE - Create: CR-secret (AWS IAM creds), CR-configmap (CW exporter config), CR
	$(KUBE_CLIENT) apply -f cloudwatch/ --validate=false -n $(NAMESPACE)

cloudwatch-delete: ## CLOUDWATCH EXAMPLE - Delete: CR, CR-secret, CR-configmap
	$(KUBE_CLIENT) delete -f cloudwatch/ -n $(NAMESPACE) || true

## Probe ##

probe-create: ## PROBE EXAMPLE - Create: CR-configmap (blackbox modules config), CR, Target-SM
	$(KUBE_CLIENT) apply -f probe/ --validate=false -n $(NAMESPACE)

probe-delete: ## PROBE EXAMPLE - Delete: Target-SM, CR, CR-configmap
	$(KUBE_CLIENT) delete -f probe/ -n $(NAMESPACE) || true

## Sendgrid ##

sendgrid-create: ## SENDGRID EXAMPLE - Create: CR-secret (username/apikey), CR
	$(KUBE_CLIENT) apply -f sendgrid/ --validate=false -n $(NAMESPACE)

sendgrid-delete: ## SENDGRID EXAMPLE - Delete: CR, CR-secret
	$(KUBE_CLIENT) delete -f sendgrid/ -n $(NAMESPACE) || true

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-33s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
