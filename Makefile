# Current Operator version
VERSION ?= 0.3.0-alpha.11
# Image URL to use all building/pushing image targets
IMG ?= quay.io/3scale/prometheus-exporter-operator:v$(VERSION)
# Default catalog image
CATALOG_IMG ?= quay.io/3scale/prometheus-exporter-operator-bundle:catalog
# Default bundle image tag
BUNDLE_IMG ?= quay.io/3scale/prometheus-exporter-operator-bundle:$(VERSION)

ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

#############################
### Makefile requirements ###
#############################

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')

# Download operator-sdk binary if necesasry
OPERATOR_SDK_RELEASE = v1.5.0
OPERATOR_SDK = $(shell pwd)/bin/operator-sdk-$(OPERATOR_SDK_RELEASE)
OPERATOR_SDK_DL_URL = https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_RELEASE)/operator-sdk_$(OS)_$(ARCH)
$(OPERATOR_SDK):
	mkdir -p $(shell pwd)/bin
	curl -sL -o $(OPERATOR_SDK) $(OPERATOR_SDK_DL_URL)
	chmod +x $(OPERATOR_SDK)

# Download operator package manager if necessary
OPM_RELEASE = v1.16.1
OPM = $(shell pwd)/bin/opm-$(OPM_RELEASE)
OPM_DL_URL = https://github.com/operator-framework/operator-registry/releases/download/$(OPM_RELEASE)/$(OS)-$(ARCH)-opm
$(OPM):
	mkdir -p $(shell pwd)/bin
	curl -sL -o $(OPM) $(OPM_DL_URL)
	chmod +x $(OPM)

# Download kind locally if necessary
KIND_RELEASE = v0.10.0
KIND = $(shell pwd)/bin/kind-$(KIND_RELEASE)
KIND_DL_URL = https://github.com/kubernetes-sigs/kind/releases/download/$(KIND_RELEASE)/kind-$(OS)-$(ARCH)
$(KIND):
	mkdir -p $(shell pwd)/bin
	curl -sL -o $(KIND) $(KIND_DL_URL)
	chmod +x $(KIND)

# Download kuttl locally if necessary for e2e tests
KUTTL_RELEASE = 0.9.0
KUTTL = $(shell pwd)/bin/kuttl-v$(KUTTL_RELEASE)
KUTTL_DL_URL = https://github.com/kudobuilder/kuttl/releases/download/v$(KUTTL_RELEASE)/kubectl-kuttl_$(KUTTL_RELEASE)_$(OS)_x86_64
$(KUTTL):
	mkdir -p $(shell pwd)/bin
	curl -sL -o $(KUTTL) $(KUTTL_DL_URL)
	chmod +x $(KUTTL)

# Download kustomize locally if necessary, preferring the $(pwd)/bin path over global if both exist.
.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize:
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.5.4/kustomize_v3.5.4_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif

# Download ansible-operator locally if necessary, preferring the $(pwd)/bin path over global if both exist.
.PHONY: ansible-operator
ANSIBLE_OPERATOR = $(shell pwd)/bin/ansible-operator
ansible-operator:
ifeq (,$(wildcard $(ANSIBLE_OPERATOR)))
ifeq (,$(shell which ansible-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(ANSIBLE_OPERATOR)) ;\
	curl -sSLo $(ANSIBLE_OPERATOR) https://github.com/operator-framework/operator-sdk/releases/download/v1.5.0/ansible-operator_$(OS)_$(ARCH) ;\
	chmod +x $(ANSIBLE_OPERATOR) ;\
	}
else
ANSIBLE_OPERATOR = $(shell which ansible-operator)
endif
endif

###########################
### Kubebuilder targets ###
###########################

all: docker-build

# Run against the configured Kubernetes cluster in ~/.kube/config
run: ansible-operator
	$(ANSIBLE_OPERATOR) run

# Install CRDs into a cluster
install: kustomize
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

# Uninstall CRDs from a cluster
uninstall: kustomize
	$(KUSTOMIZE) build config/crd | kubectl delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: kustomize
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | kubectl apply -f -

# Undeploy controller in the configured Kubernetes cluster in ~/.kube/config
undeploy: kustomize
	$(KUSTOMIZE) build config/default | kubectl delete -f -

# Build the docker image
docker-build:
	docker build -t ${IMG} .

# Push the docker image
docker-push:
	docker push ${IMG}

.PHONY: bundle ## Generate bundle manifests and metadata, then validate generated files.
bundle: $(OPERATOR_SDK) kustomize
	$(OPERATOR_SDK) generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | $(OPERATOR_SDK) generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	$(OPERATOR_SDK) bundle validate ./bundle

.PHONY: bundle-build ## Build the bundle image.
bundle-build:
	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

#########################
#### Release targets ####
#########################
prepare-alpha-release: bundle

prepare-release: bundle
	$(MAKE) bundle CHANNELS=alpha,stable DEFAULT_CHANNEL=alpha

bundle-push:
	docker push $(BUNDLE_IMG)

catalog-build: $(OPM)
	$(OPM) index add \
		--build-tool docker \
		--mode semver-skippatch \
		--bundles $(BUNDLE_IMG) \
		--from-index $(CATALOG_IMG) \
		--tag $(CATALOG_IMG)

catalog-push:
	docker push $(CATALOG_IMG)

bundle-publish: bundle-build bundle-push catalog-build catalog-push

get-new-release:
	@hack/new-release.sh v$(VERSION)

############################################
#### Targets to manually test with Kind ####
############################################

## Runs a k8s kind cluster for testing
kind-create: export KUBECONFIG = ${PWD}/kubeconfig
kind-create: $(KIND)
	$(KIND) create cluster --wait 5m

## Deletes the kind cluster
kind-delete: $(KIND)
	$(KIND) delete cluster

## Deploys the operator in the kind cluster for testing
kind-deploy: export KUBECONFIG = ${PWD}/kubeconfig
kind-deploy: docker-build $(KIND)
	$(KIND) load docker-image $(IMG)
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/testing | kubectl apply -f -

# Run kuttl e2e tests in the kind cluster
test-e2e: export KUBECONFIG = ${PWD}/kubeconfig
test-e2e: kind-create kind-deploy $(KUTTL)
	$(KUTTL) test