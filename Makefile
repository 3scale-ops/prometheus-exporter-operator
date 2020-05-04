.PHONY: operator-image-update operator-create operator-delete grafana-dashboards-create grafana-dashboards-delete prometheus-rules-create prometheus-rules-delete help

.DEFAULT_GOAL := help

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THISDIR_PATH := $(patsubst %/,%,$(abspath $(dir $(MKFILE_PATH))))

KUBE_CLIENT ?= kubectl # It can be used "oc" or "kubectl"
IMAGE ?= quay.io/3scale/prometheus-exporter-operator
VERSION ?= v1.1.0
NAMESPACE ?= example-application-monitoring

operator-image-build: # OPERATOR IMAGE - Build operator Docker image
	operator-sdk build $(IMAGE):$(VERSION)

operator-image-push: # OPERATOR IMAGE - Push operator Docker image to remote registry
	docker push $(IMAGE):$(VERSION)

operator-image-update: operator-image-build operator-image-push ## OPERATOR IMAGE - Build and Push Operator Docker image to remote registry

namespace-create: # NAMESPACE MANAGEMENT - Create namespace for the operator
	$(KUBE_CLIENT) create namespace $(NAMESPACE) || true
	$(KUBE_CLIENT) label namespace $(NAMESPACE) monitoring-key=middleware || true

operator-create: namespace-create ## OPERATOR MAIN - Create/Update Operator objects (remember to set correct image on deploy/operator.yaml)
	$(KUBE_CLIENT) create -f deploy/crds/ops.3scale.net_prometheusexporters_crd.yaml --validate=false || true
	$(KUBE_CLIENT) apply -f deploy/service_account.yaml -n $(NAMESPACE)
	$(KUBE_CLIENT) apply -f deploy/role.yaml -n $(NAMESPACE)
	$(KUBE_CLIENT) apply -f deploy/role_binding.yaml -n $(NAMESPACE)
	$(KUBE_CLIENT) apply -f deploy/operator.yaml -n $(NAMESPACE)

operator-delete: ## OPERATOR MAIN - Delete Operator objects
	$(KUBE_CLIENT) delete -f deploy/operator.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/role_binding.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/role.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/service_account.yaml -n $(NAMESPACE) || true

grafana-dashboards-create: namespace-create ## GRAFANA DASHBOARDS - Create Grafana Dashboards (Memcached, Redis, MySQL, PostgreSQL, Sphinx)
	$(KUBE_CLIENT) apply -f grafana-dashboards/ -n $(NAMESPACE)

grafana-dashboards-delete: ## GRAFANA DASHBOARDS - Delete Grafana Dashboards (Memcached, Redis, MySQL, PostgreSQL, Sphinx)
	$(KUBE_CLIENT) delete -f grafana-dashboards/ -n $(NAMESPACE) || true

prometheus-rules-create: namespace-create ## PROMETHEUS RULES - Create Prometheus Rules (Memcached, Redis, MySQL, PostgreSQL, Sphinx)
	$(KUBE_CLIENT) apply -f prometheus-rules/ -n $(NAMESPACE)

prometheus-rules-delete: ## PROMETHEUS RULES - Delete Prometheus Rules (Memcached, Redis, MySQL, PostgreSQL, Sphinx)
	$(KUBE_CLIENT) delete -f prometheus-rules/ -n $(NAMESPACE) || true

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-33s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
