output "public_ip" {
  value = oci_core_instance.rallly_instance.public_ip
}

output "ralllyUrl" {
  value = "https://${var.fqdn}"
}