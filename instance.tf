data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 2
}

data "oci_identity_domain" "identity_domain" {
  domain_id = var.identity_domain
}

data "oci_core_images" "oracle_linux_10" {
  compartment_id = var.compartment_ocid

  operating_system         = "Oracle Linux"
  operating_system_version = "10"

  shape = var.instance_shape.instanceShape

  # Only available images
  state = "AVAILABLE"

  # Sort so newest is first
  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

locals {
  oracle_linux_10_image_id = data.oci_core_images.oracle_linux_10.images[0].id
  resource_name_prefix     = "rallly-${substr(md5(lower(var.fqdn)), 0, 8)}"
}

resource "random_pet" "server" {
  keepers = {
    user_data = base64encode(templatefile("./userdata/bootstrap", {
      allowed_emails            = var.allowed_emails
      deploy_bucket_name        = oci_objectstorage_bucket.deploy_bucket.name
      fqdn                      = var.fqdn
      objectstorage_namespace   = data.oci_objectstorage_namespace.os_namespace.namespace
      smtp_host                 = "smtp.email.${var.region}.oci.oraclecloud.com"
      smtp_password_secret_ocid = var.rallly_smtp_credential_secret_ocid
      smtp_user                 = var.rallly_smtp_credential_username
    }))
  }
}

resource "random_uuid7" "unique-id" {
}

resource "oci_identity_domains_dynamic_resource_group" "rallly_dynamic_group" {
  idcs_endpoint = data.oci_identity_domain.identity_domain.url
  matching_rule = "instance.id=${oci_core_instance.rallly_instance.id}"
  display_name  = "${local.resource_name_prefix}-dynamic-group"
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]
}

resource "oci_identity_policy" "rallly_policy" {
  compartment_id = var.compartment_ocid
  description    = "${local.resource_name_prefix}-policy"
  name           = "${local.resource_name_prefix}-policy"
  statements = ["Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to read secret-family in compartment id ${var.compartment_ocid} where target.secret.id = '${var.rallly_smtp_credential_secret_ocid}'",
    "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to use instances in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to use volume-attachments in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to read buckets in compartment id ${var.compartment_ocid}",
  "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to read objects in compartment id ${var.compartment_ocid}"]
}

resource "oci_core_volume" "data_volume" {
  compartment_id      = var.compartment_ocid
  availability_domain = oci_core_instance.rallly_instance.availability_domain
  display_name        = "data-${oci_core_instance.rallly_instance.display_name}"
  size_in_gbs         = 50
  vpus_per_gb         = 10
  lifecycle {
    # Prevent destruction in production because this will have psqldata on it
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "data_volume_attachment" {
  attachment_type                   = "iscsi"
  instance_id                       = oci_core_instance.rallly_instance.id
  volume_id                         = oci_core_volume.data_volume.id
  device                            = "/dev/oracleoci/oraclevdb"
  is_agent_auto_iscsi_login_enabled = true
  use_chap                          = true
}

resource "oci_core_instance" "rallly_instance" {
  availability_domain = coalesce(var.ad_name, data.oci_identity_availability_domain.ad.name)
  compartment_id      = var.compartment_ocid
  display_name        = "rallly-${random_pet.server.id}"
  shape               = var.instance_shape.instanceShape

  shape_config {
    ocpus                     = var.instance_shape.ocpus
    memory_in_gbs             = var.instance_shape.memory
    baseline_ocpu_utilization = var.baseline_ocpu_utilization
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.public_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "exampleinstance"
    nsg_ids                   = [oci_core_network_security_group.web-sg.id]
  }

  source_details {
    source_type             = "image"
    source_id               = local.oracle_linux_10_image_id
    boot_volume_size_in_gbs = "60"
  }

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name          = "Block Volume Management"
    }
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = random_pet.server.keepers.user_data
    unique-id           = random_uuid7.unique-id.result
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_vcn" "rallly_vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "RalllyVcn"
  dns_label      = "ralllyvcn"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "RalllyInternetGateway"
  vcn_id         = oci_core_vcn.rallly_vcn.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.rallly_vcn.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_subnet" "public_subnet" {
  availability_domain = coalesce(var.ad_name, data.oci_identity_availability_domain.ad.name)
  cidr_block          = "10.1.20.0/24"
  display_name        = "RalllyPublicSubnet"
  dns_label           = "ralllypublic"
  security_list_ids   = [oci_core_vcn.rallly_vcn.default_security_list_id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.rallly_vcn.id
  route_table_id      = oci_core_vcn.rallly_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.rallly_vcn.default_dhcp_options_id
}

resource "oci_core_network_security_group" "web-sg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.rallly_vcn.id
  display_name   = "Web Server Security Group"
}

resource "oci_core_network_security_group_security_rule" "https" {
  network_security_group_id = oci_core_network_security_group.web-sg.id

  description = "HTTPS"
  direction   = "INGRESS"
  protocol    = 6
  source_type = "CIDR_BLOCK"
  source      = "0.0.0.0/0"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "http" {
  network_security_group_id = oci_core_network_security_group.web-sg.id

  description = "HTTP"
  direction   = "INGRESS"
  protocol    = 6
  source_type = "CIDR_BLOCK"
  source      = "0.0.0.0/0"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}
