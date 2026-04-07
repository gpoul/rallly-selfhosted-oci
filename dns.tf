locals {
  fqdn_parts  = split(".", trimsuffix(var.fqdn, "."))
  target_zone = "${join(".", slice(local.fqdn_parts, 1, length(local.fqdn_parts)))}."
}

data "oci_dns_zone" "target_zone" {
  zone_name_or_id = local.target_zone
  scope           = "GLOBAL"
}

resource "oci_dns_rrset" "a-records" {
  domain          = var.fqdn
  rtype           = "A"
  zone_name_or_id = data.oci_dns_zone.target_zone.id

  items {
    domain = var.fqdn
    rdata  = oci_core_instance.rallly_instance.public_ip
    rtype  = "A"
    ttl    = 60
  }
}

resource "oci_dns_rrset" "spf-record" {
  domain          = var.fqdn
  rtype           = "TXT"
  zone_name_or_id = data.oci_dns_zone.target_zone.id

  items {
    domain = var.fqdn
    rdata  = "v=spf1 include:eu.rp.oracleemaildelivery.com ~all"
    rtype  = "TXT"
    ttl    = 60
  }
}

resource "oci_dns_rrset" "cname-dkim-record" {
  domain          = oci_email_dkim.rallly_dkim.dns_subdomain_name
  rtype           = "CNAME"
  zone_name_or_id = data.oci_dns_zone.target_zone.id

  items {
    domain = oci_email_dkim.rallly_dkim.dns_subdomain_name
    rdata  = oci_email_dkim.rallly_dkim.cname_record_value
    rtype  = "CNAME"
    ttl    = 60
  }

  lifecycle {
    ignore_changes       = [items]
    replace_triggered_by = [oci_email_dkim.rallly_dkim.id]
  }
}
