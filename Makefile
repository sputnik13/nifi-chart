SHELL := /bin/bash

IDENTIFIER ?= $(shell date +%s)
RELEASE_NAME ?= $(shell whoami)-${IDENTIFIER}
NAMESPACE_NAME ?= $(shell whoami)-${IDENTIFIER}
NIFI_CHART_DIR ?= nifi
DEPLOYED_NS ?= ""
DEPLOYED_RELEASE ?= ${DEPLOYED_NS}
STRUCTURED_LOG ?= false


.phony: add-helm-incubator-repository
add-helm-incubator-repository:
ifneq (https://charts.helm.sh/incubator, $(shell helm repo list -o json | jq -e -r '.[] | select(.name=="incubator") | .url'))
	helm repo add --force-update incubator https://charts.helm.sh/incubator && helm repo update
endif

.phony: update-nifi-dependency
update-nifi-dependency: add-helm-incubator-repository
	cd nifi && helm dep up --skip-refresh

.phony: deploy-nifi
deploy-nifi: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-toolkit
deploy-secured-nifi-with-toolkit: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: delete-nifi-release
delete-nifi-release:
	helm delete ${RELEASE_NAME} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-with-openid-authentication-with-toolkit
deploy-secured-nifi-with-openid-authentication-with-toolkit: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-ldap-authentication-with-toolkit
deploy-secured-nifi-with-ldap-authentication-with-toolkit: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/ldap-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-user-certs
deploy-secured-nifi-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: update-secret-with-more-certs
update-secret-with-more-certs:
	kubectl -n ${DEPLOYED_NS} get secret ${DEPLOYED_RELEASE}-nifi-certs -o yaml > deployed_secret.yaml
	helm template ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/add-more-certs-values.yaml \
		-s templates/certs-secret.yaml \
		${NIFI_CHART_DIR}  --dry-run

.phony: deploy-secured-nifi-with-openid-authentication-with-user-certs
deploy-secured-nifi-with-openid-authentication-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-ldap-authentication-with-user-certs
deploy-secured-nifi-with-ldap-authentication-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/ldap-values.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

# Minikube related targets
.phony: deploy-nifi-on-minikube
deploy-nifi-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-toolkit-on-minikube
deploy-secured-nifi-with-toolkit-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-openid-authentication-with-toolkit-on-minikube
deploy-secured-nifi-with-openid-authentication-with-toolkit-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-ldap-authentication-with-toolkit-on-minikube
deploy-secured-nifi-with-ldap-authentication-with-toolkit-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-user-certs-on-minikube
deploy-secured-nifi-with-user-certs-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-openid-authentication-with-user-certs-on-minikube
deploy-secured-nifi-with-openid-authentication-with-user-certs-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}

.phony: deploy-secured-nifi-with-ldap-authentication-with-user-certs-on-minikube
deploy-secured-nifi-with-ldap-authentication-with-user-certs-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/ldap-values.yaml \
		${NIFI_CHART_DIR} \
		-n ${NAMESPACE_NAME} \
		--set nifi.logging.structured=${STRUCTURED_LOG}