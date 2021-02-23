.PHONY: operator-image-update operator-local-deploy operator-manual-deploy operator-manual-delete operator-olm-deploy operator-olm-delete manifests-generate manifests-verify manifests-push prometheus-rules-deploy prometheus-rules-delete help

.DEFAULT_GOAL := help

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THISDIR_PATH := $(patsubst %/,%,$(abspath $(dir $(MKFILE_PATH))))
UNAME := $(shell uname)

ifeq (${UNAME}, Linux)
  INPLACE_SED=sed -i
else ifeq (${UNAME}, Darwin)
  INPLACE_SED=sed -i ""
endif

VERSION ?= v0.2.4
MANIFESTS_VERSION ?= $(subst v,,$(VERSION))
REGISTRY ?= quay.io
ORG ?= 3scale
PROJECT ?= prometheus-exporter-operator
MANIFESTS_PROJECT ?= 3scaleops
IMAGE ?= $(REGISTRY)/$(ORG)/$(PROJECT)
AUTH_TOKEN = $(shell curl -sH "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d '{"user": {"username": "$(QUAY_USERNAME)", "password": "${QUAY_PASSWORD}"}}' | jq -r '.token')
KUBE_CLIENT ?= kubectl # It can be used "oc" or "kubectl"
NAMESPACE ?= prom-exporter
NAMESPACE_MARKETPLACE ?= openshift-marketplace

## Operator ##
operator-image-build: # OPERATOR IMAGE - Build operator Docker image
	operator-sdk build $(IMAGE):$(VERSION)

operator-image-push: # OPERATOR IMAGE - Push operator Docker image to remote registry
	docker push $(IMAGE):$(VERSION)

operator-image-update: operator-image-build operator-image-push ## OPERATOR IMAGE - Build and Push Operator Docker image to remote registry

namespace-create: # NAMESPACE MANAGEMENT - Create namespace for the operator
	$(KUBE_CLIENT) create namespace $(NAMESPACE) || true
	$(KUBE_CLIENT) label namespace $(NAMESPACE) monitoring-key=middleware || true

operator-local-deploy: namespace-create ## OPERATOR LOCAL DEPLOY - Deploy Operator locally for dev purpose
	operator-sdk run --local --watch-namespace $(NAMESPACE)

operator-manual-deploy: namespace-create ## OPERATOR MANUAL DEPLOY - Deploy Operator objects (namespace, CRD, service account, role, role binding and operator deployment)
	$(KUBE_CLIENT) apply -f deploy/crds/monitoring.3scale.net_prometheusexporters_crd.yaml --validate=false || true
	$(KUBE_CLIENT) apply -f deploy/service_account.yaml -n $(NAMESPACE)
	$(KUBE_CLIENT) apply -f deploy/role.yaml -n $(NAMESPACE)
	$(KUBE_CLIENT) apply -f deploy/role_binding.yaml -n $(NAMESPACE)
	$(INPLACE_SED) 's|REPLACE_IMAGE|$(IMAGE):$(VERSION)|g' deploy/operator.yaml
	$(KUBE_CLIENT) apply -f deploy/operator.yaml -n $(NAMESPACE)
	$(INPLACE_SED) 's|$(IMAGE):$(VERSION)|REPLACE_IMAGE|g' deploy/operator.yaml

operator-manual-delete: ## OPERATOR MANUAL DEPLOY - Delete Operator manual objects (except CRD/namespace for caution)
	$(KUBE_CLIENT) delete -f deploy/operator.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/role_binding.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/role.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/service_account.yaml -n $(NAMESPACE) || true

operator-olm-deploy: namespace-create ## OPERATOR OLM DEPLOY - Deploy Operator OLM objects (namespace, operator source, operator group, operator subscription)
	$(KUBE_CLIENT) apply -f deploy/operator_source.yaml -n $(NAMESPACE_MARKETPLACE)
	$(INPLACE_SED) 's|REPLACE_NAMESPACE|$(NAMESPACE)|g' deploy/operator_group.yaml
	$(KUBE_CLIENT) apply -f deploy/operator_group.yaml -n $(NAMESPACE)
	$(INPLACE_SED) 's|$(NAMESPACE)|REPLACE_NAMESPACE|g' deploy/operator_group.yaml
	$(INPLACE_SED) 's|REPLACE_NAMESPACE_MARKETPLACE|$(NAMESPACE_MARKETPLACE)|g' deploy/operator_subscription.yaml
	$(KUBE_CLIENT) apply -f deploy/operator_subscription.yaml -n $(NAMESPACE)
	$(INPLACE_SED) 's|$(NAMESPACE_MARKETPLACE)|REPLACE_NAMESPACE_MARKETPLACE|g' deploy/operator_subscription.yaml

operator-olm-delete: ## OPERATOR OLM DEPLOY - Delete Operator OLM objects (except namespace for caution)
	$(KUBE_CLIENT) delete -f deploy/operator_subscription.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete clusterserviceversion  $(PROJECT).$(VERSION) -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/operator_group.yaml -n $(NAMESPACE) || true
	$(KUBE_CLIENT) delete -f deploy/operator_source.yaml -n $(NAMESPACE_MARKETPLACE) || true

operator-test-e2e:
	kind create cluster || true
	make operator-manual-deploy --no-print-directory
	$(KUBE_CLIENT) apply -f deploy/crds/monitoring.3scale.net_v1alpha1_prometheusexporter_cr.yaml -n $(NAMESPACE)
	$(KUBE_CLIENT) get prometheusexporter example-memcached -n $(NAMESPACE)
	TIMEOUT=0; until [ $${TIMEOUT} -eq 60 ] || $(KUBE_CLIENT) wait deployment prometheus-exporter-memcached-example-memcached --for=condition=available -n $(NAMESPACE); do sleep 2;((TIMEOUT++)); done ; if [ $${TIMEOUT} -eq 60 ]; then exit -1; else echo "SUCCESS: Operator created memcached CR deployment"; fi
	kind delete cluster

manifests-generate: ## OPERATOR OLM CSV - Generate CSV Manifests
	$(INPLACE_SED) 's|REPLACE_IMAGE|$(IMAGE):$(VERSION)|g' deploy/operator.yaml
	operator-sdk generate csv --make-manifests=false --csv-version $(MANIFESTS_VERSION) --update-crds
	$(INPLACE_SED) 's|$(IMAGE):$(VERSION)|REPLACE_IMAGE|g' deploy/operator.yaml

manifests-verify: ## OPERATOR OLM CSV - Verify CSV manifests
	operator-courier --verbose verify --ui_validate_io deploy/olm-catalog/$(PROJECT)/

manifests-push: ## OPERATOR OLM CSV - Push CSV manifests to remote application registry
	operator-courier --verbose push deploy/olm-catalog/$(PROJECT)/ $(MANIFESTS_PROJECT) $(PROJECT) $(MANIFESTS_VERSION) "$(AUTH_TOKEN)"

## Prometheus rules ##
prometheus-rules-deploy: namespace-create ## PROMETHEUS RULES - Create Prometheus Rules (Memcached, Redis, MySQL, PostgreSQL, Sphinx, Elasticsearch, Cloudwatch, Probe)
	$(KUBE_CLIENT) apply -f prometheus-rules/ -n $(NAMESPACE)

prometheus-rules-delete: ## PROMETHEUS RULES - Delete Prometheus Rules (Memcached, Redis, MySQL, PostgreSQL, Sphinx, Elasticsearch, Cloudwatch, Probe)
	$(KUBE_CLIENT) delete -f prometheus-rules/ -n $(NAMESPACE) || true

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-33s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
