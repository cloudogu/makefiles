SHELL := /bin/bash

IMAGE_TAG?=${IMAGE_REGISTRY}/coder/coder-${TEMPLATE_NAME}:${VERSION}
REUSE_TEST_WORKSPACE?=false

#BUILD_DIR given via variables.mk
TEMPLATE_DIR=${WORKDIR}/template
CONTAINER_BUILD_DIR=${WORKDIR}/container
SECRETS_DIR=${WORKDIR}/secrets
CODER_LIB_PATH=${BUILD_DIR}/make/coder-lib.sh

RELEASE_DIR=${WORKDIR}/release
MAKE_CHANGE_TOKEN_DIR=${RELEASE_DIR}/make
CONTAINER_IMAGE_CHANGE_TOKEN?=${MAKE_CHANGE_TOKEN_DIR}/${TEMPLATE_NAME}_image_id.txt
CONTAINER_IMAGE_TAR?=${RELEASE_DIR}/${TEMPLATE_NAME}.tar
CONTAINER_IMAGE_TARGZ?=${RELEASE_DIR}/${TEMPLATE_NAME}.tar.gz
CONTAINER_IMAGE_TRIVY_SCAN_JSON?=${RELEASE_DIR}/trivy.json
CONTAINER_IMAGE_TRIVY_SCAN_TABLE?=${RELEASE_DIR}/trivy.txt
CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_TABLE?=${RELEASE_DIR}/trivy_critical.txt
CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_JSON?=${RELEASE_DIR}/trivy_critical.json

IMAGE_REGISTRY?=registry.cloudogu.com
IMAGE_REGISTRY_USER_FILE?=${SECRETS_DIR}/harbor-user
IMAGE_REGISTRY_PW_FILE?=${SECRETS_DIR}/harbor-pw

CHANGELOG_FILE=${WORKDIR}/CHANGELOG.md
TEMPLATE_RELEASE_TAR_GZ=${RELEASE_DIR}/${TEMPLATE_NAME}-template.tar.gz

TEST_WORKSPACE_PREFIX?=test-${TEMPLATE_NAME}
# only set if coder is installed, so that there is no problem with build and release targets
CODER_USER?=$(shell if [ -x "$(command -v coder)" ]; then coder users show me -o json | jq -r '.username'; else echo ""; fi )

CONTAINER_BIN?=$(shell if [ -x "$(command -v podman)" ]; then echo "podman"; else echo "docker"; fi)

EXCLUDED_TEMPLATE_FILES?=rich-parameters.yaml variables.yaml


##@ Coder template development

.PHONY: buildImage
buildImage: ${CONTAINER_IMAGE_CHANGE_TOKEN} ## build the container image

${CONTAINER_IMAGE_CHANGE_TOKEN}:
	@. ${CODER_LIB_PATH} && buildImage ${IMAGE_TAG} ${CONTAINER_BUILD_DIR} ${SECRETS_DIR} ${CONTAINER_BIN}
	@mkdir -p ${MAKE_CHANGE_TOKEN_DIR}
	@${CONTAINER_BIN} image ls --format="{{.ID}}" ${IMAGE_TAG} > ${CONTAINER_IMAGE_CHANGE_TOKEN}

.PHONY: uploadTemplate
uploadTemplate: ## upload template to coder server
	@. ${CODER_LIB_PATH} && uploadTemplate ${TEMPLATE_DIR} ${TEMPLATE_NAME}

.PHONY: startTestWorkspace
startTestWorkspace: ## start a test workspace with coder
	 @. ${CODER_LIB_PATH} && startTestWorkspace ${CODER_USER} ${TEMPLATE_DIR} ${TEST_WORKSPACE_PREFIX}  ${TEMPLATE_NAME} ${REUSE_TEST_WORKSPACE}

.PHONY: createImageRelease
createImageRelease: ${CONTAINER_IMAGE_TARGZ} ## export the container image as a tar.gz

${CONTAINER_IMAGE_TAR}: ${CONTAINER_IMAGE_CHANGE_TOKEN}
	${CONTAINER_BIN} save "${IMAGE_TAG}" -o ${CONTAINER_IMAGE_TAR}

${CONTAINER_IMAGE_TARGZ}: ${CONTAINER_IMAGE_TAR}
	gzip -f --keep "${CONTAINER_IMAGE_TAR}"

.PHONY: trivyscanImage
trivyscanImage: ${CONTAINER_IMAGE_TRIVY_SCAN_JSON} ${CONTAINER_IMAGE_TRIVY_SCAN_TABLE} ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_TABLE} ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_JSON} ## do a trivy scan for the workspace image in various output formats

${CONTAINER_IMAGE_TRIVY_SCAN_JSON}: ${CONTAINER_IMAGE_TAR}
	${CONTAINER_BIN} run --rm --pull=always \
		-v "trivy-cache:/root/.cache" \
		-v "${CONTAINER_IMAGE_TAR}:/tmp/image.tar" \
		aquasec/trivy -q \
		image --scanners vuln --input /tmp/image.tar -f json --timeout 15m \
		> ${CONTAINER_IMAGE_TRIVY_SCAN_JSON}

${CONTAINER_IMAGE_TRIVY_SCAN_TABLE}: ${CONTAINER_IMAGE_TRIVY_SCAN_JSON}
	@. ${CODER_LIB_PATH} && \
    		doTrivyConvert "--format table" ${CONTAINER_IMAGE_TRIVY_SCAN_TABLE} ${CONTAINER_BIN} ${CONTAINER_IMAGE_TRIVY_SCAN_JSON}

${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_TABLE}: ${CONTAINER_IMAGE_TRIVY_SCAN_JSON}
	@. ${CODER_LIB_PATH} && \
		doTrivyConvert "--format table --severity CRITICAL" ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_TABLE} ${CONTAINER_BIN} ${CONTAINER_IMAGE_TRIVY_SCAN_JSON}

${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_JSON}: ${CONTAINER_IMAGE_TRIVY_SCAN_JSON}
	@. ${CODER_LIB_PATH} && \
    		doTrivyConvert "--format json --severity CRITICAL" ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_JSON} ${CONTAINER_BIN} ${CONTAINER_IMAGE_TRIVY_SCAN_JSON}

.PHONY: createTemplateRelease
createTemplateRelease: ## generate template.tar.gz with all files needed for customers
	# remove release dir first as 'cp' cannot merge and will place the source dir inside the target dir if it already exists
	rm -rf "${RELEASE_DIR}/${TEMPLATE_NAME}"
	cp -r "${TEMPLATE_DIR}" "${RELEASE_DIR}/${TEMPLATE_NAME}/"
	#copy changelog
	cp "${CHANGELOG_FILE}" "${RELEASE_DIR}/${TEMPLATE_NAME}/"
	# remove excludes
	for file in "${EXCLUDED_TEMPLATE_FILES}"; do \
		rm -f "${RELEASE_DIR}/${TEMPLATE_NAME}/$$file"; \
	done
	tar -czf "${RELEASE_DIR}/${TEMPLATE_NAME}-template.tar.gz" -C "${RELEASE_DIR}" "${TEMPLATE_NAME}"

.PHONY: createRelease ## generate template- and container archives and the trivy scans
createRelease: createTemplateRelease ${CONTAINER_IMAGE_TARGZ} trivyscanImage ## create the image.tar.gz, template.tar.gz and trivy scans

.PHONY: cleanCoderRelease
cleanCoderRelease: ## clean release directory
	rm -rf "${RELEASE_DIR}"
	mkdir -p "${RELEASE_DIR}"

.PHONY: imageRegistryLogin
imageRegistryLogin: ${IMAGE_REGISTRY_USER_FILE} ${IMAGE_REGISTRY_PW_FILE} ## log into the registry
	@${CONTAINER_BIN} login -u "$$(cat ${IMAGE_REGISTRY_USER_FILE})" --password-stdin '${IMAGE_REGISTRY}' < ${IMAGE_REGISTRY_PW_FILE}

.PHONY: imageRegistryLogout
imageRegistryLogout: ## log out of the registry
	@${CONTAINER_BIN} logout '${IMAGE_REGISTRY}'

.PHONY: pushImage
pushImage: ## push the container image into the registry
	${CONTAINER_BIN} push ${IMAGE_TAG}

.PHONY: uploadRelease
uploadRelease: createTemplateRelease ${CONTAINER_IMAGE_TARGZ} ${CONTAINER_IMAGE_TRIVY_SCAN_JSON} ${CONTAINER_IMAGE_TRIVY_SCAN_TABLE} ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_TABLE} ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_JSON} ## upload release artifacts to nexus
	@. ${CODER_LIB_PATH} && uploadToNexus ${TEMPLATE_RELEASE_TAR_GZ} ${TEMPLATE_NAME} ${VERSION}
	@. ${CODER_LIB_PATH} && uploadToNexus ${CONTAINER_IMAGE_TRIVY_SCAN_JSON} ${TEMPLATE_NAME} ${VERSION}
	@. ${CODER_LIB_PATH} && uploadToNexus ${CONTAINER_IMAGE_TRIVY_SCAN_TABLE} ${TEMPLATE_NAME} ${VERSION}
	@. ${CODER_LIB_PATH} && uploadToNexus ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_TABLE} ${TEMPLATE_NAME} ${VERSION}
	@. ${CODER_LIB_PATH} && uploadToNexus ${CONTAINER_IMAGE_TRIVY_SCAN_CRITICAL_JSON} ${TEMPLATE_NAME} ${VERSION}
	@. ${CODER_LIB_PATH} && uploadToNexus ${CONTAINER_IMAGE_TARGZ} ${TEMPLATE_NAME} ${VERSION}

