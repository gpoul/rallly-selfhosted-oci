resource "oci_email_email_domain" "rallly_email_domain" {
  compartment_id = var.compartment_ocid
  name           = var.fqdn
}

resource "oci_email_sender" "rallly_sender" {
  compartment_id = var.compartment_ocid
  email_address  = "noreply@${var.fqdn}"
  depends_on     = [oci_email_email_domain.rallly_email_domain]
}

resource "oci_email_dkim" "rallly_dkim" {
  email_domain_id = oci_email_email_domain.rallly_email_domain.id
}