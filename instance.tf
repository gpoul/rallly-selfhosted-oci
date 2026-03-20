data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 2
}

variable rallly_smtp_credential_username {
}
variable rallly_smtp_credential_secret_ocid {
}

resource "random_pet" "server" {
  keepers = {
    user_data = base64encode(templatefile("./userdata/bootstrap", { fqdn = var.fqdn, smtp_user = var.rallly_smtp_credential_username, smtp_password_secret_ocid = var.rallly_smtp_credential_secret_ocid } ))
  }
}

resource "random_uuid7" "unique-id" {
}

variable "flex_instance_image_ocid" {
  type = map(string)
  default = {
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaanri6q2ifldmautmdge26ruuqxkuvq7yctv24cwktotpg7tknur2q"
  }
}

data "oci_identity_domain" "identity_domain" {
    domain_id = "ocid1.domain.oc1..aaaaaaaazyf5gvxbczergtqlsa4l2jxo6px7vbn3gdsutgsda34wduyitj5a"
}

resource "oci_identity_domains_dynamic_resource_group" "rallly_dynamic_group" {
    idcs_endpoint = data.oci_identity_domain.identity_domain.url
    matching_rule = "instance.id=${oci_core_instance.test_instance.id}"
    display_name = "rallly-dynamic-group"
    schemas = ["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]
}

resource "oci_identity_policy" "rallly_policy" {
    compartment_id = var.compartment_ocid
    description = "rallly-policy"
    name = "rallly-policy"
    statements = [ "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to read secret-family in compartment id ${var.compartment_ocid} where target.secret.id = '${var.rallly_smtp_credential_secret_ocid}'",
        "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to use instances in compartment id ${var.compartment_ocid}",
        "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to use volume-attachments in compartment id ${var.compartment_ocid}",
        "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to read buckets in compartment id ${var.compartment_ocid}",
        "Allow dynamic-group id ${oci_identity_domains_dynamic_resource_group.rallly_dynamic_group.ocid} to read objects in compartment id ${var.compartment_ocid}" ]
}

resource "oci_core_volume" "test_volume" {
    compartment_id = var.compartment_ocid
    availability_domain = oci_core_instance.test_instance.availability_domain
    display_name = "data-${oci_core_instance.test_instance.display_name}"
    size_in_gbs = 50
    vpus_per_gb = 10
    lifecycle {
        # Prevent destruction in production because this will have psqldata on it
        #prevent_destroy = true
    }
}

resource "oci_core_volume_attachment" "test_volume_attachment" {
    attachment_type = "iscsi"
    instance_id = oci_core_instance.test_instance.id
    volume_id = oci_core_volume.test_volume.id
    device = "/dev/oracleoci/oraclevdb"
    is_agent_auto_iscsi_login_enabled = true
    use_chap = true
}

resource "oci_core_instance" "test_instance" {
  availability_domain        = data.oci_identity_availability_domain.ad.name
  compartment_id             = var.compartment_ocid
  display_name               = "rallly-${random_pet.server.id}"
  shape                      = var.instance_shape

  shape_config {
    ocpus = 2
    memory_in_gbs = 4
    #baseline_ocpu_utilization = "BASELINE_1_8"
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.test_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "exampleinstance"
    //subnet_cidr          = "10.1.20.0/24"
    nsg_ids                   = [oci_core_network_security_group.web-sg.id]
  }

  source_details {
    source_type = "image"
    source_id = var.flex_instance_image_ocid[var.region]
    boot_volume_size_in_gbs = "60"
  }

  # Apply the following flag only if you wish to preserve the attached boot volume upon destroying this instance
  # Setting this and destroying the instance will result in a boot volume that should be managed outside of this config.
  # When changing this value, make sure to run 'terraform apply' so that it takes effect before the resource is destroyed.
  #preserve_boot_volume = true

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name = "Block Volume Management"
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

resource "oci_core_vcn" "test_vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "TestVcn"
  dns_label      = "testvcn"
}

resource "oci_core_internet_gateway" "test_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "TestInternetGateway"
  vcn_id         = oci_core_vcn.test_vcn.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.test_vcn.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.test_internet_gateway.id
  }
}

resource "oci_core_subnet" "test_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
 cidr_block          = "10.1.20.0/24"
  //ipv4_cidr_blocks          = ["10.1.20.0/24", "10.1.21.0/24"]
  display_name        = "TestSubnet"
  dns_label           = "testsubnet"
  security_list_ids   = [oci_core_vcn.test_vcn.default_security_list_id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.test_vcn.id
  route_table_id      = oci_core_vcn.test_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.test_vcn.default_dhcp_options_id
}

resource "oci_core_network_security_group" "web-sg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.test_vcn.id
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


output "public_ip" {
  value = oci_core_instance.test_instance.public_ip
}

