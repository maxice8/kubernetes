.PHONY: all help k3s cert_manager certs traefik whoami forgejo syncthing uptime_kuma

log_error = (>&2 printf '\033[0m[ \033[31mERR\033[0m ] %s\n' "$(1)" 2>&1)

# Default target: list all available targets
all: help

help:
	@echo "Available targets:"
	@echo "  k3s                 - Installs k3s Kubernetes."
	@echo "  cert_manager        - Installs Rancher and Cert-Manager."
	@echo "  certs               - Configures Cert-Manager with Cloudflare and creates a certificate."
	@echo "  traefik             - Adds an HTTP to HTTPS redirect with Traefik."
	@echo "  whoami              - Deploys a 'whoami' application for testing."
	@echo "  forgejo             - Deploys Forgejo (Git service)."
	@echo "  syncthing           - Deploys Syncthing with Tailscale integration."
	@echo "  uptime_kuma         - Deploys Uptime Kuma with Tailscale integration."

## Setup Targets

k3s:
	@if [ -z "$(DOMAIN)" ]; then $(call log_error,Error: DOMAIN environment variable is required.); exit 1; fi
	curl -sfL https://get.k3s.io | sh -s server --flannel-backend=wireguard-native
	mkdir -p ~/.kube
	sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
	sudo chown $(shell id -u):$(shell id -g) ~/.kube/config

cert_manager:
	@if [ -z "$(DOMAIN)" ]; then $(call log_error,Error: DOMAIN environment variable is required.); exit 1; fi
	helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
	kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -
	helm repo add jetstack https://charts.jetstack.io
	helm repo update
	helm install cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--create-namespace \
		--set crds.enabled=true \
		--wait
	helm install rancher rancher-latest/rancher --namespace cattle-system \
		--set hostname=rancher.$(DOMAIN) \
		--set replicas=1 \
		--set ingress.tls.source=secret

certs:
	@exit_code=0; \
	if [ -z "$(DOMAIN)" ]; then \
		$(call log_error,Error: DOMAIN environment variable is required.); \
		exit_code=1; \
	fi; \
	if [ -z "$(EMAIL)" ]; then \
		$(call log_error,Error: EMAIL environment variable is required.); \
		exit_code=1; \
	fi; \
	if [ -z "$(CLOUDFLARE_API_TOKEN)" ]; then \
		$(call log_error,Error: CLOUDFLARE_API_TOKEN environment variable is required.); \
		exit_code=1; \
	fi; \
	if [ $$exit_code -ne 0 ]; then exit $$exit_code; fi
	cat cloudflare-certs/cloudflare.yaml | envsubst | kubectl apply -f -
	cat cloudflare-certs/cloudflare-issuer.yaml | envsubst | kubectl apply -f -
	cat rancher/certificate.yaml | envsubst | kubectl apply -f -

traefik:
	kubectl apply -f traefik/redirect-https.yaml

whoami:
	@if [ -z "$(DOMAIN)" ]; then \
		$(call log_error,Error: DOMAIN environment variable is required.); \
		exit 1; \
	fi
	cat whoami.yaml | envsubst | kubectl apply -f -

forgejo:
	@if [ -z "$(DOMAIN)" ]; then $(call log_error,Error: DOMAIN environment variable is required.); exit 1; fi
	cat forgejo.yaml | envsubst | kubectl apply -f -

syncthing:
	@if [ -z "$(TAILSCALE_KEY)" ]; then $(call log_error,Error: TAILSCALE_KEY environment variable is required.); exit 1; fi
	cat syncthing.yaml | envsubst | kubectl apply -f -

uptime_kuma:
	@if [ -z "$(TAILSCALE_KEY)" ]; then $(call log_error,Error: TAILSCALE_KEY environment variable is required.); exit 1; fi
	cat uptime-kuma.yaml | envsubst | kubectl apply -f -