output "cluster_id" {
  description = "OKE cluster OCID read from the oci-oke stack"
  value       = local.cluster_id
}

output "vault_id" {
  description = "OCI Vault OCID read from the foundation stack"
  value       = local.foundation_vault_id
}

output "cloudflare_api_token_secret_name" {
  description = "OCI Vault secret name read from the foundation stack"
  value       = local.cloudflare_api_token_secret_name
}

output "betterstack_heartbeat_url_secret_name" {
  description = "OCI Vault secret name read from the foundation stack for the Better Stack heartbeat URL"
  value       = local.betterstack_heartbeat_url_secret_name
}
