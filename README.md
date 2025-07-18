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

Set the variables `CLOUDFLARE_API_TOKEN` and `EMAIL` and run the following command, this will create a certificate-issuer that authenticates with cloudflare.

```sh
cat cloudflare-certs/cloudflare.yaml | envsubst | kubectl apply -f -
cat cloudflare-certs/cloudflare-issuer.yaml | envsubst | kubectl apply -f -
```

Now create a certificate object:

```sh
cat rancher/certificate.yaml | envsubst | kubectl apply -f
```

After a while the page at `https://rancher.${DOMAIN}` should have a nice valid certificate.

### Whoami

> Add DNS entry for whoami.${DOMAIN}

I like to use this to test that everything is working.

```sh
kubectl create namespace whoami
cat whoami/deployment.yaml | envsubst | kubectl apply -f -
cat whoami/service.yaml | envsubst | kubectl apply -f -
cat whoami/ingress.yaml | envsubst | kubectl apply -f -
```

#### Sources

List of sources that helped me set this up:

- [the k8s rabbithole (#5) - Rancher v2.6 with DNS-01 TLS/SSL Certificates (via Let's Encrypt and Cloudflare)](https://www.raptorswithhats.com/the-k8s-rabbit/)
