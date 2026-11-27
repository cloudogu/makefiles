# Targets for developing v3 dogus with cldk.
# This module includes k8s.mk and can be included together with k8s-dogu.mk.

ifeq (${K8S_MK_INCLUDE_MARKER}, )
	include ${BUILD_DIR}/make/k8s.mk
endif

## Variables

BINARY_CLDK?=$(UTILITY_BIN_PATH)/cldk
BINARY_CLDK_VERSION?=1.0.0
BINARY_CLDK_URL?=https://github.com/cloudogu/cldk/releases/download/v${BINARY_CLDK_VERSION}/cldk_${BINARY_CLDK_VERSION}_linux_amd64.tar.gz
BINARY_CLDK_SUM?=d105b16655a1ad2d9eb3dde2ffd416de30fc547e1e6f538ffcc19d119f566a0d
BINARY_CLDK_ARCHIVE_PATH?=cldk
BINARY_CLDK_ARCHIVE_STRIP?=0

# Settings of `cldk dogu dev-push`, derived from RUNTIME_ENV, KUBE_CONTEXT_NAME and NAMESPACE of k8s.mk.
# Each of them can be overridden by setting the CLDK_DEV_* variable in the environment or in the .env.
# cldk takes only host[:port] as registry address, so for "remote" the registry namespace (e.g. /testing or /ci) becomes the dogu namespace in the dev registry.
CLDK_DEV_REG?=$(IMAGE_PUSH_REGISTRY_HOST)
CLDK_DEV_CLUSTER_REG?=$(CES_REGISTRY_HOST)
CLDK_DEV_PLAIN_HTTP?=$(if $(filter remote,$(RUNTIME_ENV)),,true)
CLDK_DEV_DOGU_NAMESPACE?=$(if $(filter remote,$(RUNTIME_ENV)),$(patsubst /%,%,$(CES_REGISTRY_NAMESPACE)))
CLDK_DEV_KUBE_CONTEXT?=$(KUBE_CONTEXT_NAME)
CLDK_DEV_KUBE_NAMESPACE?=$(or $(NAMESPACE),ecosystem)

# Additional arguments for `cldk dogu dev-push`, e.g. CLDK_DEV_PUSH_ARGS=--dry-run. Flags override the CLDK_DEV_* variables.
CLDK_DEV_PUSH_ARGS?=

##@ K8s - Dogu v3

.PHONY: dogu-apply
dogu-apply: isProduction check-docker-credentials ${BINARY_CLDK} ## Builds the v3 dogu and pushes/installs it under a new dev version with `cldk dogu dev-push`.
	@CLDK_DEV_REG="$(CLDK_DEV_REG)" \
		CLDK_DEV_CLUSTER_REG="$(CLDK_DEV_CLUSTER_REG)" \
		CLDK_DEV_PLAIN_HTTP="$(CLDK_DEV_PLAIN_HTTP)" \
		CLDK_DEV_DOGU_NAMESPACE="$(CLDK_DEV_DOGU_NAMESPACE)" \
		CLDK_DEV_KUBE_CONTEXT="$(CLDK_DEV_KUBE_CONTEXT)" \
		CLDK_DEV_KUBE_NAMESPACE="$(CLDK_DEV_KUBE_NAMESPACE)" \
		$(BINARY_CLDK) dogu dev-push $(CLDK_DEV_PUSH_ARGS)

##@ K8s - Download Dogu v3 Utilities

.PHONY: install-cldk
install-cldk: ${BINARY_CLDK} ## Installs cldk.

# Removes an installed cldk whose version differs from BINARY_CLDK_VERSION, so that ${BINARY_CLDK} downloads it again.
.PHONY: cldk-version-check
cldk-version-check:
	@[ ! -x ${BINARY_CLDK} ] \
		|| [ "$$(${BINARY_CLDK} version 2>/dev/null | awk '{print $$2}')" = "${BINARY_CLDK_VERSION}" ] \
		|| { echo "Removing outdated cldk $$(${BINARY_CLDK} version 2>/dev/null)" ; rm -f ${BINARY_CLDK} ; }

${BINARY_CLDK}: cldk-version-check $(UTILITY_BIN_PATH)
	$(call curl-get-tool-from-tar,$(BINARY_CLDK),$(BINARY_CLDK_URL),$(BINARY_CLDK_SUM),$(BINARY_CLDK_ARCHIVE_PATH),$(BINARY_CLDK_ARCHIVE_STRIP))
