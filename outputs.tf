output "public_ip" {
  value = oci_core_instance.rallly_instance.public_ip
}

output "ralllyUrl" {
  value = "https://${var.fqdn}"
}

output "rallly_log_group_id" {
  value = oci_logging_log_group.rallly.id
}

output "rallly_application_log_id" {
  value = oci_logging_log.rallly_application_logs.id
}

output "rallly_postgres_log_id" {
  value = oci_logging_log.rallly_postgres_logs.id
}
