resource "oci_logging_log_group" "rallly" {
  compartment_id = var.compartment_ocid
  display_name   = "${local.resource_name_prefix}-logs"
  description    = "Logs collected from the Rallly instance"
}

resource "oci_logging_log" "rallly_application_logs" {
  display_name       = "rallly-application-logs"
  log_group_id       = oci_logging_log_group.rallly.id
  log_type           = "CUSTOM"
  is_enabled         = true
  retention_duration = 30
}

resource "oci_logging_log" "rallly_postgres_logs" {
  display_name       = "rallly-postgres-logs"
  log_group_id       = oci_logging_log_group.rallly.id
  log_type           = "CUSTOM"
  is_enabled         = true
  retention_duration = 30
}

resource "oci_logging_unified_agent_configuration" "rallly_application_logs" {
  compartment_id = var.compartment_ocid
  display_name   = "${local.resource_name_prefix}-application-logs"
  description    = "Collect Rallly application logs from the instance boot volume"
  is_enabled     = true

  group_association {
    group_list = [oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid]
  }

  service_configuration {
    configuration_type = "LOGGING"

    destination {
      log_object_id = oci_logging_log.rallly_application_logs.id
    }

    sources {
      name        = "rallly-application-log-file"
      source_type = "LOG_TAIL"
      paths       = ["/var/log/rallly/rallly.log"]

      advanced_options {
        is_read_from_head = false
      }

      parser {
        parser_type         = "CRI"
        is_merge_cri_fields = true
      }
    }
  }
}

resource "oci_logging_unified_agent_configuration" "rallly_postgres_logs" {
  compartment_id = var.compartment_ocid
  display_name   = "${local.resource_name_prefix}-postgres-logs"
  description    = "Collect Rallly Postgres logs from the instance boot volume"
  is_enabled     = true

  group_association {
    group_list = [oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid]
  }

  service_configuration {
    configuration_type = "LOGGING"

    destination {
      log_object_id = oci_logging_log.rallly_postgres_logs.id
    }

    sources {
      name        = "rallly-postgres-log-file"
      source_type = "LOG_TAIL"
      paths       = ["/var/log/rallly/postgres.log"]

      advanced_options {
        is_read_from_head = false
      }

      parser {
        parser_type         = "CRI"
        is_merge_cri_fields = true
      }
    }
  }
}
