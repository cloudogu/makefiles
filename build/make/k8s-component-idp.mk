NAMESPACE ?= ecosystem
DEPLOYED_IDP_RELEASE_NAME ?= lop-idp
IDP_WORKING_DIR ?= target
IDP_CHART_DIR = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)
IDP_CHART_FILE = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/Chart.yaml
IDP_VALUES_FILE = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/values.yaml
IDP_DEV_VALUES_FILE = $(IDP_WORKING_DIR)/$(DEPLOYED_IDP_RELEASE_NAME)/values-dev.yaml
CES_REGISTRY_NAMESPACE_SUB = $(patsubst /%,%,$(CES_REGISTRY_NAMESPACE))

##@ K8s - LOP-IDP development

.PHONY: helm-apply-idp
helm-apply-idp: helm-prepare-idp helm-update-idp ## Development target to deploy a single subchart from the lop-idp in the cluster. It pulls the current installed idp chart, updates the subchart and the values with dev images and updates the idp chart in the cluster.

.PHONY: helm-prepare-idp
helm-prepare-idp: pull-idp build-subchart-idp update-subchart-dependency-idp update-subchart-values-idp

.PHONY: helm-update-idp
helm-update-idp:
	@helm dep up "$(IDP_CHART_DIR)"
	@helm -n "$(NAMESPACE)" upgrade -i "$(DEPLOYED_IDP_RELEASE_NAME)" "$(IDP_CHART_DIR)" -f "$(IDP_DEV_VALUES_FILE)" --reuse-values

.PHONY: build-subchart-idp
build-subchart-idp: helm-chart-import

.PHONY: update-subchart-values-idp # Overwrite this target if paths are different or multiple images are required.
update-subchart-values-idp:
	@echo "Updating values in $(IDP_DEV_VALUES_FILE)..."
	@yq -n '."$(ARTIFACT_ID)".image.registry = "$(CES_REGISTRY_HOST)"' > "$(IDP_DEV_VALUES_FILE)" # Always create a new file
	@yq -i '."$(ARTIFACT_ID)".image.repository = "$(CES_REGISTRY_NAMESPACE_SUB)/$(ARTIFACT_ID)/$(GIT_BRANCH)"' "$(IDP_DEV_VALUES_FILE)"
	@yq -i '."$(ARTIFACT_ID)".image.tag = "$(COMPONENT_DEV_VERSION)"' "$(IDP_DEV_VALUES_FILE)"

.PHONY: update-subchart-dependency-idp
update-subchart-dependency-idp:
	@echo "Updating subchart $(ARTIFACT_ID) in $(IDP_CHART_FILE)..."
	@yq -i '(.dependencies[] | select(.name == "$(ARTIFACT_ID)")) |= (.repository = "oci://$(CES_REGISTRY_HOST)/$(HELM_ARTIFACT_NAMESPACE)" | .version = "$(COMPONENT_DEV_VERSION)")' "$(IDP_CHART_FILE)"

.PHONY: pull-idp
pull-idp:
	@set -euo pipefail; \
	echo "Checking IDP Component status..."; \
	idpStatus=$$(kubectl -n "$(NAMESPACE)" get comp "$(DEPLOYED_IDP_RELEASE_NAME)" --no-headers -o custom-columns=":status.status" 2>/dev/null || true); \
	if [[ "$${idpStatus}" != "installed" ]]; then \
	  echo "error: IDP Component is not installed (Status: $${idpStatus})"; \
	  exit 1; \
	fi; \
	echo "IDP Component status: $${idpStatus}"; \
	\
	idpInstalledVersion=$$(kubectl -n "$(NAMESPACE)" get comp "$(DEPLOYED_IDP_RELEASE_NAME)" --no-headers -o custom-columns=":status.installedVersion"); \
	echo "IDP Component installed version: $${idpInstalledVersion}"; \
	\
	idpRegistryNamespace=$$(kubectl -n "$(NAMESPACE)" get comp "$(DEPLOYED_IDP_RELEASE_NAME)" --no-headers -o custom-columns=":spec.namespace"); \
	echo "IDP Component registry namespace: $${idpRegistryNamespace}"; \
	\
	registryProperties=$$(kubectl -n "$(NAMESPACE)" get cm component-operator-helm-repository -o jsonpath='{.data.endpoint}{" "}{.data.schema}{" "}{.data.insecureTls}{" "}{.data.plainHttp}'); \
	read -r registryEndpoint registrySchema registryInsecureTls registryPlainHttp < <(echo "$${registryProperties}"); \
	echo "Using registry $${registrySchema}://$${registryEndpoint} with insecureTls $${registryInsecureTls} and plainHttp $${registryPlainHttp}"; \
	\
	echo "Creating working dir $(IDP_WORKING_DIR)"; \
	mkdir -p "$(IDP_WORKING_DIR)"; \
	\
	if [[ -d "$(IDP_CHART_DIR)" ]]; then \
	  echo "Cleaning up old working chart dir"; \
	  rm -rf "$(IDP_CHART_DIR)"; \
	fi; \
	\
	tlsOption=""; \
	if [[ "$${registryInsecureTls}" == "true" ]]; then \
	  tlsOption="--insecure-skip-tls-verify"; \
	fi; \
	\
	plainHttpOption=""; \
	if [[ "$${registryPlainHttp}" == "true" ]]; then \
	  plainHttpOption="--plain-http"; \
	fi; \
	\
	echo "Pull IDP Helm-Chart..."; \
	helm pull --untar --destination "$(IDP_WORKING_DIR)" "$${registrySchema}://$${registryEndpoint}/$${idpRegistryNamespace}/$(DEPLOYED_IDP_RELEASE_NAME)" --version "$${idpInstalledVersion}" $${tlsOption} $${plainHttpOption}
