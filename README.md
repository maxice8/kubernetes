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

Required variables: `CLOUDFLARE_API_TOKEN`, `EMAIL`

This creates a certificate issuer using the cloudflare API that responds to the annotation of `cert-manager.io/cluster-issuer: letsencrypt-prod`

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

### Forgejo

> Add DNS entry for git.${DOMAIN}

Required variables: `DOMAIN`

```sh
kubectl create namespace forgejo
cat forgejo/pvc.yaml | envsubst | kubectl apply -f -
cat forgejo/deployment.yaml | envsubst | kubectl apply -f -
cat forgejo/service.yaml | envsubst | kubectl apply -f -
cat forgejo/ingress.yaml | envsubst | kubectl apply -f -
```

### Tailscale

This will add all the bits and pieces required for running [Tailscale](https://tailscale.com) sidecars, because they are easier to deal with than the k8s operators.

Note that we assume you are using the `default` namespace to share all the Tailscale stuff, if you want to run each deployment with tailscale in a separate namespace you will need to apply for each namespace you are using.

#### Role-Based Control Access (RBAC)

```sh
kubectl apply -f tailscale/rbac.yaml
```

#### Auth Key

Generate your key in [Tailscale](https://login.tailscale.com/admin/settings/keys) and use it here

```sh
# Reminder that you have to rotate this key every 90 days (or less if you configured so)
cat tailscale/authkey.yaml | TAILSCALE_KEY=<REPLACE_WITH_YOUR_AUTH_KEY> envsbust | kubectl apply -f -
```

#### Sources

List of sources that helped me set this up:

- [the k8s rabbithole (#5) - Rancher v2.6 with DNS-01 TLS/SSL Certificates (via Let's Encrypt and Cloudflare)](https://www.raptorswithhats.com/the-k8s-rabbit/)
- [How to Secure Kubernetes Access with Tailscale](https://tailscale.com/learn/managing-access-to-kubernetes-with-tailscale)
