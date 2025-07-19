# Kubernetes configuration

This is my configuration for kubernetes, values are replaced with `envsubst`.

## Required Variables

Each section has a `Required Variables` sentence that tells you which environment variables we expect to be set.

In some cases these variables are sensitive data (like Tailscale Authentication Keys) so they are instead used directly in the `envsubst` command.

## Setup

### k3s

> Add DNS entry for rancher.${DOMAIN} before setting up `k3s`
>
> Required environment variables: **DOMAIN**

```sh
curl -sfL https://get.k3s.io | sh
mkdir ~/.kube/config
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

### rancher + cert-manager

> Required environment variables: **DOMAIN**

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

> Required environment variables: **DOMAIN**, **EMAIL**

This creates a certificate issuer using the cloudflare API that responds to the annotation of `cert-manager.io/cluster-issuer: letsencrypt-prod`

```sh
 cat cloudflare-certs/cloudflare.yaml | CLOUDFLARE_API_TOKEN=<YOUR_CLOUDFLARE_API_TOKEN> envsubst | kubectl apply -f -
cat cloudflare-certs/cloudflare-issuer.yaml | envsubst | kubectl apply -f -
```

Now create a certificate object:

```sh
cat rancher/certificate.yaml | envsubst | kubectl apply -f
```

After a while the page at `https://rancher.${DOMAIN}` should have a nice valid certificate.

### Traefik

Add a little HTTP to HTTPS redirect

```sh
kubectl apply -f traefik/redirect-https.yaml
```

### Whoami

> Add DNS entry for whoami.${DOMAIN}
>
> Required environment variables: **DOMAIN**

I like to use this to test that everything is working.

```sh
cat whoami.yaml | envsubst | kubectl apply -f -
```

### Forgejo

> Add DNS entry for git.${DOMAIN}
>
> Required environment variables: **DOMAIN**

```sh
kubectl create namespace forgejo
cat forgejo/pvc.yaml | envsubst | kubectl apply -f -
cat forgejo/deployment.yaml | envsubst | kubectl apply -f -
cat forgejo/service.yaml | envsubst | kubectl apply -f -
cat forgejo/ingress.yaml | envsubst | kubectl apply -f -
```

### Syncthing

This will create a complete syncthing setup with the WebUI exposed over your tailscale network, the following components are created:

1. A namespace called syncthing
2. Persistent Volume Claims to store syncthing configuration and data via local-storage
3. A Tailscale sidecar setup:
   - A secret called tailscale-auth holding your authentication key
   - A serviceaccount that will modify this tailscale-auth to store data alongside the authentication key
   - RBAC policies to allow the tailscale serviceaccount to edit the tailscale-auth secret
   - A configMap to serve the Syncthing WebUI (:8384) on `syncthing.<TAILNET_NAME>.ts.net` with a valid tailscale certificate
4. A deployment using a pod with syncthing and the tailscale sidecar

```sh
 cat syncthing.yaml | TAILSCALE_KEY=<YOUR_TAILSCALE_KEY>?ephemeral=false envsubst '$TAILSCALE_KEY' | kubectl apply -f -
```

### Uptime-kuma

This will create a uptime-kuma setup with the WebUI exposed over your tailscale network, the following components are created:

This will create a complete syncthing setup with the WebUI exposed over your tailscale network, the following components are created:

1. A namespace called kuma
2. Persistent Volume Claims to store uptime-kuma data via local-storage
3. A Tailscale sidecar setup:
     - A secret called tailscale-auth holding your authentication key
     - A serviceaccount that will modify this tailscale-auth to store data alongside the authentication key
     - RBAC policies to allow the tailscale serviceaccount to edit the tailscale-auth secret
     - A configMap to serve the Uptime Kuma WebUI (:3001) on `uptime.<TAILNET_NAME>.ts.net` with a valid tailscale certificate
4. A deployment using a pod with syncthing and the tailscale sidecar

```sh
 cat uptime-kuma.yaml | TAILSCALE_KEY=<YOUR_TAILSCALE_KEY>?ephemeral=false envsubst '$TAILSCALE_KEY' | kubectl apply -f -
```

#### Sources

List of sources that helped me set this up:

- [the k8s rabbithole (#5) - Rancher v2.6 with DNS-01 TLS/SSL Certificates (via Let's Encrypt and Cloudflare)](https://www.raptorswithhats.com/the-k8s-rabbit/)
- [How to Secure Kubernetes Access with Tailscale](https://tailscale.com/learn/managing-access-to-kubernetes-with-tailscale)
- [HTTPS with Cert-Manager and Letsencrypt](https://k3s.rocks/https-cert-manager-letsencrypt/)
