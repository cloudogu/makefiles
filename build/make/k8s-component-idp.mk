NAMESPACE ?= ecosystem
DEPLOYED_IDP_RELEASE_NAME ?= lop-idp
IDP_WORKING_DIR ?= target
IDP_CHART_DIR = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)
IDP_CHART_DEPENDENCY_DIR = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/charts
IDP_CHART_FILE = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/Chart.yaml
IDP_CHART_LOCK_FILE = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/Chart.lock
IDP_VALUES_FILE = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/values.yaml
IDP_DEV_VALUES_FILE = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/values-dev.yaml
CES_REGISTRY_NAMESPACE_SUB = $(patsubst /%,%,$(CES_REGISTRY_NAMESPACE))
HELM_PULL_REGISTRY_HOST = $(CES_REGISTRY_HOST)
HELM_PULL_REGISTRY_ARGS =
ifeq ($(RUNTIME_ENV),k3d)
  HELM_PULL_REGISTRY_HOST = localhost:5002
  HELM_PULL_REGISTRY_ARGS = "--plain-http"
endif
IDP_BUILD_VERSION := $(shell date +%s)
IDP_DEV_VERSION_SUFFIX=-dev.${IDP_BUILD_VERSION}

# Workflow:
# - Pull current IDP chart from registry (either dev registry in k3d or registry.cloudogu.com)
# - Build and push the dev chart from this artifact (e.g. usermgt)
# - Pull the dev chart and inject it into the local IDP chart in charts dir.
# - Update Chart.yaml and values.yaml in local IDP chart.
# - Important: Push the local IDP chart with injected subchart to the registry so that other IDP components won't override changes.
# - Important: Do not execute a `helm dependency update` command because this will start trouble with different dependencies located in HTTP and HTTPS registries.
# - Apply local IDP chart in cluster
.PHONY: helm-apply-idp
helm-apply-idp: helm-prepare-idp helm-update-idp

.PHONY: helm-prepare-idp
helm-prepare-idp: pull-idp build-subchart-idp helm-dependency-pull-idp update-subchart-dependency-idp update-subchart-values-idp helm-push-idp

.PHONY: helm-push-idp
helm-push-idp:
	@IDP_VERSION=$$(${BINARY_YQ} '.version' "$(IDP_CHART_FILE)"); \
	IDP_DEV_VERSION_SUFFIX="$(IDP_DEV_VERSION_SUFFIX)"; \
	if [[ ! "$$IDP_VERSION" == *dev* ]]; then \
	  echo "IDP Helm-Chart is not a dev version. Changing version to dev..."; \
	  IDP_VERSION="$$IDP_VERSION" IDP_DEV_VERSION_SUFFIX="$$IDP_DEV_VERSION_SUFFIX" \
	  ${BINARY_YQ} -i '.version = strenv(IDP_VERSION) + strenv(IDP_DEV_VERSION_SUFFIX)' "$(IDP_CHART_FILE)"; \
	  IDP_VERSION="$$IDP_VERSION$$IDP_DEV_VERSION_SUFFIX"; \
	fi; \
	IDP_PACKAGE_NAME="$(IDP_CHART_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)-$$IDP_VERSION.tgz"; \
	echo "Build helm package $$IDP_PACKAGE_NAME"; \
	${BINARY_HELM} package "$(IDP_CHART_DIR)" -d "$(IDP_CHART_DIR)";\
    ${BINARY_HELM} push "$$IDP_PACKAGE_NAME" "oci://$(IMAGE_PUSH_REGISTRY_HOST)/$(HELM_ARTIFACT_NAMESPACE)" "$(HELM_PULL_REGISTRY_ARGS)"

.PHONY: helm-dependency-pull-idp
helm-dependency-pull-idp:
	@rm -f "$(IDP_CHART_LOCK_FILE)"
	${BINARY_HELM} pull "oci://$(HELM_PULL_REGISTRY_HOST)/$(HELM_ARTIFACT_NAMESPACE)/$(ARTIFACT_ID)" --version "$(COMPONENT_DEV_VERSION)" --destination "$(IDP_CHART_DEPENDENCY_DIR)" $(HELM_PULL_REGISTRY_ARGS)

.PHONY: helm-update-idp
helm-update-idp:
	@${BINARY_HELM} -n "$(NAMESPACE)" upgrade -i "$(DEPLOYED_IDP_RELEASE_NAME)" "$(IDP_CHART_DIR)" -f "$(IDP_DEV_VALUES_FILE)" --reuse-values

.PHONY: build-subchart-idp
build-subchart-idp: helm-chart-import

.PHONY: update-subchart-values-idp # Overwrite this target if path are different or multiple images are required.
update-subchart-values-idp:
	@echo "Updating values in $(IDP_DEV_VALUES_FILE)..."
	@${BINARY_YQ} -n '."$(ARTIFACT_ID)".image.registry = "$(CES_REGISTRY_HOST)"' > "$(IDP_DEV_VALUES_FILE)" # Always create a new file
	@${BINARY_YQ} -i '."$(ARTIFACT_ID)".image.repository = "$(CES_REGISTRY_NAMESPACE_SUB)/$(ARTIFACT_ID)/$(GIT_BRANCH)"' "$(IDP_DEV_VALUES_FILE)"
	@${BINARY_YQ} -i '."$(ARTIFACT_ID)".image.tag = "$(VERSION)"' "$(IDP_DEV_VALUES_FILE)" # Use regular version for images and no "dev" prefix with random numbers because the imagePullPolicy: Always will ensure to load the newest image in the cluster.

.PHONY: update-subchart-dependency-idp
update-subchart-dependency-idp:
	@echo "Updating subchart $(ARTIFACT_ID) in $(IDP_CHART_FILE)..."
	@${BINARY_YQ} -i '(.dependencies[] | select(.name == "$(ARTIFACT_ID)")) |= (.repository = "oci://$(HELM_PULL_REGISTRY_HOST)/$(HELM_ARTIFACT_NAMESPACE)" | .version = "$(COMPONENT_DEV_VERSION)")' "$(IDP_CHART_FILE)"

.PHONY: pull-idp
pull-idp:
	@set -euo pipefail; \
	idpInstalledVersion=$$(${BINARY_HELM} -n "$(NAMESPACE)" get metadata "$(DEPLOYED_IDP_RELEASE_NAME)" -o yaml | ${BINARY_YQ} '.version'); \
	echo "IDP Component installed version: $${idpInstalledVersion}"; \
	idpRegistryNamespace=$$(kubectl -n "$(NAMESPACE)" get comp "$(DEPLOYED_IDP_RELEASE_NAME)" --no-headers -o custom-columns=":spec.namespace"); \
	echo "IDP Component registry namespace: $${idpRegistryNamespace}"; \
	registryProperties=$$(kubectl -n "$(NAMESPACE)" get cm component-operator-helm-repository -o jsonpath='{.data.endpoint}{" "}{.data.schema}{" "}{.data.insecureTls}{" "}{.data.plainHttp}'); \
	read -r registryEndpoint registrySchema registryInsecureTls registryPlainHttp < <(echo "$${registryProperties}"); \
	if [[ ! $${idpInstalledVersion} == *dev* ]]; then \
	  registryEndpoint=registry.cloudogu.com; \
	  registryPlainHttp=false; \
    elif [[ "$(RUNTIME_ENV)" == "k3d" ]]; then \
      registryEndpoint="localhost:5002"; \
      registryPlainHttp=true; \
	fi; \
	echo "Using registry $${registrySchema}://$${registryEndpoint} with insecureTls $${registryInsecureTls} and plainHttp $${registryPlainHttp}"; \
	echo "Creating working dir $(IDP_WORKING_DIR)"; \
	mkdir -p "$(IDP_WORKING_DIR)"; \
	if [[ -d "$(IDP_CHART_DIR)" ]]; then \
	  echo "Cleaning up old working chart dir"; \
	  rm -rf "$(IDP_CHART_DIR)"; \
	fi; \
	tlsOption=""; \
	if [[ "$${registryInsecureTls}" == "true" ]]; then \
	  tlsOption="--insecure-skip-tls-verify"; \
	fi; \
	plainHttpOption=""; \
	if [[ "$${registryPlainHttp}" == "true" ]]; then \
	  plainHttpOption="--plain-http"; \
	fi; \
	echo "Pull IDP Helm-Chart..."; \
	${BINARY_HELM} pull --untar --destination "$(IDP_WORKING_DIR)" "$${registrySchema}://$${registryEndpoint}/$${idpRegistryNamespace}/$(DEPLOYED_IDP_RELEASE_NAME)" --version "$${idpInstalledVersion}" $${tlsOption} $${plainHttpOption}
