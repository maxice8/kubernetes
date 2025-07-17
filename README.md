# Kubernetes configuration

This is my configuration for kubernetes, values are replaced with `envsubst`.

## Setup

### k3s

> Add DNS entry for rancher.${DOMAIN} before setting up `k3s`

```sh
curl -sfL https://get.k3s.io | sh
mkdir ~/.kube/config
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

### rancher + cert-manager

```sh
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --create-namespace \
     --set crds.enabled=true

helm install rancher rancher-latest/rancher --namespace cattle-system \
     --set hostname=rancher.${DOMAIN} \
     --set replicas=1 \
     --set ingress.tls.source=secret \
     --create-namespace
```

### Certs

Set the variables `CLOUDFLARE_API_TOKEN` and `EMAIL` and run the following command

```sh
cat cloudflare-certs/*.yaml | envsubst | kubectl apply -f-
```

After a while the page at `https://rancher.${DOMAIN}` should have a nice valid certificate.

### Whoami

> Add DNS entry for whoami.${DOMAIN}

I like to use this to test that everything is working.

```sh
cat whoami/*.yaml | envsubst | kubectl apply -f-
```