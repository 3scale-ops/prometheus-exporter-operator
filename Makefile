# Update this value when you upgrade the version of your project.
# To re-generate a bundle for another specific version without changing the standard setup, you can:
# - use the VERSION as arg of the bundle target (e.g make bundle VERSION=0.0.2)
# - use environment variables to overwrite this value (e.g export VERSION=0.0.2)
VERSION ?= 0.9.0

# CHANNELS define the bundle channels used in the bundle.
# Add a new line here if you would like to change its default config. (E.g CHANNELS = "candidate,fast,stable")
# To re-generate a bundle for other specific channels without changing the standard setup, you can:
# - use the CHANNELS as arg of the bundle target (e.g make bundle CHANNELS=candidate,fast,stable)
# - use environment variables to overwrite this value (e.g export CHANNELS="candidate,fast,stable")
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif

# DEFAULT_CHANNEL defines the default channel used in the bundle.
# Add a new line here if you would like to change its default config. (E.g DEFAULT_CHANNEL = "stable")
# To re-generate a bundle for any other default channel without changing the default setup, you can:
# - use the DEFAULT_CHANNEL as arg of the bundle target (e.g make bundle DEFAULT_CHANNEL=stable)
# - use environment variables to overwrite this value (e.g export DEFAULT_CHANNEL="stable")
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# IMAGE_TAG_BASE defines the docker.io namespace and part of the image name for remote images.
# This variable is used to construct full image tags for bundle and catalog images.
#
# For example, running 'make bundle-build bundle-push catalog-build catalog-push' will build and push both
# 3scale.net/prometheus-exporter-operator-bundle:$VERSION and 3scale.net/prometheus-exporter-operator-catalog:$VERSION.
IMAGE_TAG_BASE ?= quay.io/3scale/prometheus-exporter-operator

# BUNDLE_IMG defines the image:tag used for the bundle.
# You can use it as an arg. (E.g make bundle-build BUNDLE_IMG=<some-registry>/<project-name-bundle>:<tag>)
BUNDLE_IMG ?= $(IMAGE_TAG_BASE)-bundle:v$(VERSION)

# The image contailer file for the bundle
BUNDLE_CONTAINER_FILE = "bundle.Dockerfile"

# BUNDLE_GEN_FLAGS are the flags passed to the operator-sdk generate bundle command
BUNDLE_GEN_FLAGS ?= -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)

# USE_IMAGE_DIGESTS defines if images are resolved via tags or digests
# You can enable this value if you would like to use SHA Based Digests
# To enable set flag to true
USE_IMAGE_DIGESTS ?= false
ifeq ($(USE_IMAGE_DIGESTS), true)
	BUNDLE_GEN_FLAGS += --use-image-digests
endif

# Image URL to use all building/pushing image targets
IMG ?= $(IMAGE_TAG_BASE):v$(VERSION)

# Container runtime
CONTAINER_RUNTIME ?= docker
CONTAINER_CTX = .
CONTAINER_FILE = "Dockerfile"

.PHONY: all
all: container-build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: container-build
container-build: ## Build container  with the manager.
	${CONTAINER_RUNTIME} buildx build \
		--platform linux/arm64,linux/amd64 \
		--tag $(IMG) --file $(CONTAINER_FILE) $(CONTAINER_CTX)

.PHONY: container-push
container-push: ## Push container image with the manager.
	${CONTAINER_RUNTIME} buildx build --push \
		--platform linux/arm64,linux/amd64 \
		--tag $(IMG) --file $(CONTAINER_FILE) $(CONTAINER_CTX)

.PHONY: container-image
container-image: ## Outputs the container image name and tag.
	@echo $(IMG)

##@ Dependencies

.PHONY: ansible-operator
ANSIBLE_OPERATOR = $(shell pwd)/bin/ansible-operator
ansible-operator: ## Download ansible-operator locally if necessary, preferring the $(pwd)/bin path over global if both exist.
ifeq (,$(wildcard $(ANSIBLE_OPERATOR)))
ifeq (,$(shell which ansible-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(ANSIBLE_OPERATOR)) ;\
	curl -sSLo $(ANSIBLE_OPERATOR) https://github.com/operator-framework/operator-sdk/releases/download/v1.24.0/ansible-operator_$(OS)_$(ARCH) ;\
	chmod +x $(ANSIBLE_OPERATOR) ;\
	}
else
ANSIBLE_OPERATOR = $(shell which ansible-operator)
endif
endif

.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v4.5.5/kustomize_v4.5.5_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif

.PHONY: opm
OPM = ./bin/opm
opm: ## Download opm locally if necessary.
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPM)) ;\
	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v1.23.0/$(OS)-$(ARCH)-opm ;\
	chmod +x $(OPM) ;\
	}
else
OPM = $(shell which opm)
endif
endif

#############################################
#### Custom Targets with extra binaries #####
#############################################

.PHONY: operator-sdk
OPERATOR_SDK_RELEASE = v1.24.0
OPERATOR_SDK = $(shell pwd)/bin/operator-sdk-$(OPERATOR_SDK_RELEASE)
OPERATOR_SDK_DL_URL = https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_RELEASE)/operator-sdk_$(OS)_$(ARCH)
operator-sdk: ## Download operator-sdk binary if necessary.
	@if [ ! -f $(OPERATOR_SDK) ]; then\
		mkdir -p $(shell pwd)/bin;\
		curl -sL -o $(OPERATOR_SDK) $(OPERATOR_SDK_DL_URL);\
		chmod +x $(OPERATOR_SDK);\
	fi

## Download kind locally if necessary.
KIND_RELEASE = v0.11.1
KIND = $(shell pwd)/bin/kind-$(KIND_RELEASE)
KIND_DL_URL = https://github.com/kubernetes-sigs/kind/releases/download/$(KIND_RELEASE)/kind-$(OS)-$(ARCH)
$(KIND):
	mkdir -p $(shell pwd)/bin
	curl -sL -o $(KIND) $(KIND_DL_URL)
	chmod +x $(KIND)

## Download kuttl locally if necessary for e2e tests.
KUTTL_RELEASE = 0.9.0
KUTTL = $(shell pwd)/bin/kuttl-v$(KUTTL_RELEASE)
KUTTL_DL_URL = https://github.com/kudobuilder/kuttl/releases/download/v$(KUTTL_RELEASE)/kubectl-kuttl_$(KUTTL_RELEASE)_$(OS)_x86_64
$(KUTTL):
	mkdir -p $(shell pwd)/bin
	curl -sL -o $(KUTTL) $(KUTTL_DL_URL)
	chmod +x $(KUTTL)

##@ Deployment

.PHONY: run
run: ansible-operator ## Run against the configured Kubernetes cluster in ~/.kube/config.
	ANSIBLE_ROLES_PATH="$(ANSIBLE_ROLES_PATH):$(shell pwd)/roles" $(ANSIBLE_OPERATOR) run

.PHONY: install
install: kustomize ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

.PHONY: uninstall
uninstall: kustomize ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl delete -f -

.PHONY: deploy
deploy: kustomize ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/manual | kubectl apply -f -

.PHONY: undeploy
undeploy: ## Undeploy controller from the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/manual | kubectl delete -f -

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')

##@ Bundle

.PHONY: bundle
bundle: operator-sdk kustomize ## Generate bundle manifests and metadata, then validate generated files.
	$(OPERATOR_SDK) generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | $(OPERATOR_SDK) generate bundle $(BUNDLE_GEN_FLAGS)
	$(OPERATOR_SDK) bundle validate ./bundle

.PHONY: bundle-build
bundle-build: ## Build the bundle image.
	$(MAKE) container-build \
		IMG=$(BUNDLE_IMG) CONTAINER_FILE=$(BUNDLE_CONTAINER_FILE)

.PHONY: bundle-push
bundle-push: ## Push the bundle image.
	$(MAKE) container-push \
		IMG=$(BUNDLE_IMG) CONTAINER_FILE=$(BUNDLE_CONTAINER_FILE)

bundle-image: ## Outputs the bundle image name.
	@$(MAKE) container-image IMG=$(BUNDLE_IMG)

# A comma-separated list of bundle images (e.g. make catalog-build BUNDLE_IMGS=example.com/operator-bundle:v0.1.0,example.com/operator-bundle:v0.2.0).
# These images MUST exist in a registry and be pull-able.
BUNDLE_IMGS ?= $(BUNDLE_IMG)

##@ Catalog

# The image tag given to the resulting catalog image (e.g. make catalog-build CATALOG_IMG=example.com/operator-catalog:v0.2.0).
CATALOG_IMG ?= $(IMAGE_TAG_BASE)-catalog:v$(VERSION)

# The image contailer file for the catalog
CATALOG_CONTAINER_FILE = "catalog/Dockerfile"

# The image docker context for the catalog
CATALOG_CONTAINER_CTX = "catalog/"

# Default catalog base image to append bundles to
CATALOG_BASE_IMG ?= $(IMAGE_TAG_BASE)-catalog:latest

# Default catalog channel file
CATALOG_CHANNEL_FILE ?= catalog/prometheus-exporter-operator/stable-channel.yaml

# Set CATALOG_BASE_IMG to an existing catalog image tag to add $BUNDLE_IMGS to that image.
ifneq ($(origin CATALOG_BASE_IMG), undefined)
FROM_INDEX_OPT := --from-index $(CATALOG_BASE_IMG)
endif

.PHONY: catalog
catalog: opm catalog-add-bundle catalog-validate  ## Update and validate the catalog with the current bundle.

catalog-render-bundle: opm # Render the current clusterserviceversion yaml from the bundle container into the catalog.
	$(OPM) render $(BUNDLE_IMGS) -oyaml > catalog/prometheus-exporter-operator/objects/prometheus-exporter-operator.v$(VERSION).clusterserviceversion.yaml

catalog-add-entry: # Adds a catalog entry if missing
	grep -Eq 'name: prometheus-exporter-operator\.v$(VERSION)$$' $(CATALOG_CHANNEL_FILE) || \
		yq -i '.entries += {"name": "prometheus-exporter-operator.v$(VERSION)","replaces":"$(shell yq '.entries[-1].name' $(CATALOG_CHANNEL_FILE))"}' $(CATALOG_CHANNEL_FILE)

.PHONY: catalog-add-bundle-to-alpha
catalog-add-bundle-to-alpha: opm catalog-render-bundle # Adds the alpha bundle to a file based catalog
	$(MAKE) catalog-add-entry CATALOG_CHANNEL_FILE=catalog/prometheus-exporter-operator/alpha-channel.yaml

.PHONY: catalog-add-bundle-to-stable
catalog-add-bundle-to-stable: opm catalog-render-bundle catalog-add-bundle-to-alpha # Adds a bundle to a file based catalog
	$(MAKE) catalog-add-entry CATALOG_CHANNEL_FILE=catalog/prometheus-exporter-operator/stable-channel.yaml

.PHONY: catalog-add-bundle
catalog-add-bundle: opm catalog-render-bundle # Adds a bundle to a file based catalog
	if echo $(VERSION) | grep -q 'alpha'; \
		then $(MAKE) catalog-add-bundle-to-alpha; \
		else $(MAKE) catalog-add-bundle-to-stable; \
	fi

.PHONY: catalog-validate
catalog-validate: # Validate the catalog files.
	$(OPM) validate catalog/prometheus-exporter-operator

catalog-build:  opm catalog-validate  ## Build the catalog image.
	$(MAKE) container-build \
		IMG=$(CATALOG_IMG) CONTAINER_FILE=$(CATALOG_CONTAINER_FILE) CONTAINER_CTX=$(CATALOG_CONTAINER_CTX)

.PHONY: catalog-push
catalog-push: opm catalog-validate ## Push a catalog image.
	$(MAKE) container-push\
		IMG=$(CATALOG_IMG) CONTAINER_FILE=$(CATALOG_CONTAINER_FILE) CONTAINER_CTX=$(CATALOG_CONTAINER_CTX)

catalog-image: ## Outputs the catalog image name.
	@$(MAKE) container-image IMG=$(CATALOG_IMG)

catalog-push-latest: ## Push the catalog with the `latest` image tag.
	$(MAKE) container-push \
			IMG=$(CATALOG_BASE_IMG) CONTAINER_FILE=$(CATALOG_CONTAINER_FILE) CONTAINER_CTX=$(CATALOG_CONTAINER_CTX)

####################################################
##### Custom Targets to release a new version ######
####################################################
##@ Release

get-new-release:
	@hack/new-release.sh v$(VERSION)

prepare-release: ## Prepare bundle release files.
	if echo $(VERSION) | grep -q 'alpha'; \
		then $(MAKE) prepare-alpha-release; \
		else $(MAKE) prepare-stable-release; \
	fi

prepare-alpha-release: bundle # Prepare alpha release.

prepare-stable-release: bundle # Prepare stable release.
	$(MAKE) bundle CHANNELS=alpha,stable DEFAULT_CHANNEL=alpha

bundle-publish: prepare-release bundle-push ## Publish new bundle.

catalog-publish: catalog-add-bundle catalog-push catalog-push-latest ## Build and push the catalog image.

release-publish: container-push bundle-publish catalog-publish ## Publish a new stable release (operator, catalog and bundle).

###################################################
#### Custom Targets to manually test with Kind ####
###################################################
##@ Testing

kind-create: export KUBECONFIG = ${PWD}/kubeconfig
kind-create: $(KIND) ## Creates a k8s kind cluster.
	$(KIND) create cluster --wait 5m || true

kind-delete: $(KIND) ## Deletes the k8s kind cluster.
	$(KIND) delete cluster

kind-deploy: export KUBECONFIG = ${PWD}/kubeconfig
kind-deploy: kustomize $(KIND) ## Deploys the operator in the k8s kind cluster.
	${CONTAINER_RUNTIME} build --tag $(IMG) \
		--file $(CONTAINER_FILE) $(CONTAINER_CTX)
	$(KIND) load docker-image $(IMG)
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/testing | kubectl apply -f -

test-e2e: export KUBECONFIG = ${PWD}/kubeconfig
test-e2e: kind-create kustomize kind-deploy $(KUTTL) ## Run kuttl e2e tests in the k8s kind cluster.
	$(KUTTL)
