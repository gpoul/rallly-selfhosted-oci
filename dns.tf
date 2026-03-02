variable fqdn {
}

resource "oci_dns_rrset" "a-records" {
    domain = var.fqdn
    rtype = "A"
    zone_name_or_id = "ocid1.dns-zone.oc1..aaaaaaaae4635kax6robbxwflitdkaizhnufoqbjkdj5lm6eujzaw7lh5cxq"

    items {
        domain = var.fqdn
        rdata = oci_core_instance.test_instance.public_ip
        rtype = "A"
        ttl = 60
    }
}

resource "oci_dns_rrset" "spf-record" {
    domain = var.fqdn
    rtype = "TXT"
    zone_name_or_id = "ocid1.dns-zone.oc1..aaaaaaaae4635kax6robbxwflitdkaizhnufoqbjkdj5lm6eujzaw7lh5cxq"

    items {
        domain = var.fqdn
        rdata = "v=spf1 include:eu.rp.oracleemaildelivery.com ~all"
        rtype = "TXT"
        ttl = 60
    }
}

resource "oci_dns_rrset" "cname-dkim-record" {
    domain = oci_email_dkim.test_dkim.dns_subdomain_name
    rtype = "CNAME"
    zone_name_or_id = "ocid1.dns-zone.oc1..aaaaaaaae4635kax6robbxwflitdkaizhnufoqbjkdj5lm6eujzaw7lh5cxq"

    items {
        domain = oci_email_dkim.test_dkim.dns_subdomain_name
        rdata = oci_email_dkim.test_dkim.cname_record_value
        rtype = "CNAME"
        ttl = 60
    }

    lifecycle {
        ignore_changes = [ items ]
        replace_triggered_by = [ oci_email_dkim.test_dkim.id ]
    }
}
