# Kubernetes configuration

This is my configuration for kubernetes, values are replaced with `envsubst`.

## Makefile

I have a Makefile that provides targets to do the setup/deployment necessary.

## Required Variables

Each section has a `Required Variables` sentence that tells you which environment variables we expect to be set.

In some cases these variables are sensitive data (like Tailscale Authentication Keys) so they are instead used directly in the `envsubst` command.

## Targets

### k3s

> Add DNS entry for rancher.${DOMAIN} before setting up `k3s`
>
> Required environment variables: **DOMAIN**

```sh
make k3s
```

### rancher + cert-manager

<!-- TODO: SPLIT RANCHER FROM CERT-MANAGER -->

> Required environment variables: **DOMAIN**

```sh
make cert_manager
```

### Certs

> Required environment variables: **DOMAIN**, **EMAIL**

This creates a certificate issuer using the cloudflare API that responds to the annotation of `cert-manager.io/cluster-issuer: letsencrypt-prod`, and an accompanying certificate for rancher.

```sh
make certs
```

After a while the page at `https://rancher.${DOMAIN}` should have a nice valid certificate.

### Traefik

Add a little HTTP to HTTPS redirect

```sh
make traefik
```

### Whoami

> Add DNS entry for whoami.${DOMAIN}
>
> Required environment variables: **DOMAIN**

I like to use this to test that everything is working.

```sh
make whoami
```

### Forgejo

> Add DNS entry for git.${DOMAIN}
>
> Required environment variables: **DOMAIN**
>
> Requires port 22 to be unused (e.g. using Tailscale for SSH) as port 22 is redirected to git in the deployment

```sh
make forgejo
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
make syncthing
```

### Uptime-kuma

This will create a uptime-kuma setup with the WebUI exposed over your tailscale network, the following components are created:

This will create a complete syncthing setup with the WebUI exposed over your tailscale network, the following components are created:

1. A namespace called kuma
2. Persistent Volume Claims to store uptime-kuma data via local-storage
3. A deployment of uptime-kuma
4. A service that connects to the port 3001 of the deployment
5. An ingress that exposes the port 3001 of the deployment over HTTPS to your tailnet

```sh
make uptime_kuma
```

#### Sources

List of sources that helped me set this up:

- [the k8s rabbithole (#5) - Rancher v2.6 with DNS-01 TLS/SSL Certificates (via Let's Encrypt and Cloudflare)](https://www.raptorswithhats.com/the-k8s-rabbit/)
- [How to Secure Kubernetes Access with Tailscale](https://tailscale.com/learn/managing-access-to-kubernetes-with-tailscale)
- [HTTPS with Cert-Manager and Letsencrypt](https://k3s.rocks/https-cert-manager-letsencrypt/)
