provider "oci" {
    region = var.region
    tenancy_ocid = var.tenancy_ocid
    user_ocid = var.current_user_ocid
    fingerprint = var.fingerprint != null ? var.fingerprint : null
    private_key = var.private_key_path != null ? var.private_key_path : null
}
