# OKE Cluster

This is my personal Kubernetes cluster on Oracle Kubernetes Engine.

The cluster is based on my reusable OKE GitOps template:

https://github.com/antief/oke-gitops-template

## What runs here

The cluster provides a small but complete cloud-native baseline:

- Oracle Kubernetes Engine on OCI
- OpenTofu-managed infrastructure
- Flux CD for GitOps reconciliation
- Envoy Gateway for public ingress
- OCI Network Load Balancer for external traffic
- Gateway API for routing
- cert-manager with Cloudflare DNS-01 for TLS certificates
- ExternalDNS for Cloudflare DNS records
- External Secrets Operator with OCI Vault
- Longhorn for persistent storage
- kube-prometheus-stack for monitoring
- Loki and Alloy for logs
- Better Stack heartbeat from inside the cluster
- `whoami` as a public smoke-test workload

The goal is to keep the cluster small, rebuildable, and understandable while still using patterns common in larger Kubernetes environments.

## How it works

Infrastructure is managed with OpenTofu. The repository separates long-lived foundation resources from the rebuildable OKE cluster layer, so the cluster can be destroyed and recreated without recreating every supporting resource.

Flux watches `main` and reconciles the Kubernetes manifests under `gitops/`.

Public traffic follows this path:

```text
Internet
  -> OCI Network Load Balancer
  -> Envoy Gateway
  -> Gateway API routes
  -> Kubernetes Services
  -> application Pods
```

Runtime secret material is stored in OCI Vault and synced into Kubernetes with External Secrets Operator.

## Reliability model

The ingress dataplane is designed to survive normal node-level disruption.

Envoy runs as a public dataplane on the cluster nodes, while application workloads can be scaled across nodes depending on the workload. This makes it possible to test rolling changes, node cycling, and rebuild workflows with minimal manual recovery.

This is a small personal environment, not a fully automated production platform.

## External uptime monitoring

Public availability is monitored outside the cluster with Better Stack. The status page and HTTP checks are configured in Better Stack, while this repository manages the in-cluster heartbeat CronJob.

The heartbeat URL is runtime secret material. Store it locally in `.env` and let `scripts/init-local-env.sh` render the ignored OpenTofu variable files:

```dotenv
BETTERSTACK_HEARTBEAT_URL="https://uptime.betterstack.com/api/v1/heartbeat/..."
```

Flux then reconciles an ExternalSecret and a small CronJob under `uptime-monitoring`. The CronJob checks in every five minutes, so Better Stack can detect cases where the cluster can no longer run scheduled workloads or reach the internet.

## Helper commands

The repository includes a `justfile` to keep common workflows short and repeatable.

The most useful commands are:

```bash
just validate   # check local setup, ignored secrets, OCI access, and plans
just plan       # show OpenTofu changes
just apply      # create or update the cluster baseline
just destroy    # destroy Flux and OKE, keep long-lived foundation resources
just rebuild    # destroy + apply
just pr branch-name "type(scope): message"
```

These commands are convenience wrappers around OpenTofu, Flux, GitHub CLI, and local validation scripts. The detailed bootstrap workflow is documented in the template repository.

## Layout

```text
terraform/foundation   Persistent OCI foundation resources
terraform/oci-oke      Rebuildable OKE infrastructure
terraform/flux         Flux bootstrap and root ownership
gitops/                Flux-managed Kubernetes manifests
```

## Reference

Detailed bootstrap, configuration, credential, and uninstall documentation is kept in the template repository instead of duplicating it here:

[oke-gitops-template](https://github.com/antief/oke-gitops-template)
