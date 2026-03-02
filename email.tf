resource "oci_email_email_domain" "test_email_domain" {
    compartment_id = var.compartment_ocid
    name = var.fqdn
}

resource "oci_email_sender" "test_sender" {
    compartment_id = var.compartment_ocid
    email_address = "noreply@${var.fqdn}"
    depends_on = [ oci_email_email_domain.test_email_domain ]
}

#resource "oci_identity_smtp_credential" "rallly_smtp_credential" {
#    description = "rallly-smtp"
#    user_id = var.user_ocid
#}

resource "oci_email_dkim" "test_dkim" {
    email_domain_id = oci_email_email_domain.test_email_domain.id
}
