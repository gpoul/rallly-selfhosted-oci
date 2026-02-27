variable "tenancy_ocid" {
}
variable "user_ocid" {
}
variable "fingerprint" {
}
variable "private_key_path" {
}
variable "compartment_ocid" {
}
variable "region" {
}
variable "instance_shape" {
  default = "VM.Standard.E5.Flex"
}
variable "ssh_public_key" {
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHasHu9ZLFZsmef78hfr7z/BsXJLSxVwSmxVFLScA/vk gpoul@Gerhards-MacBook-Air.local"
}

provider "oci" {
    region = var.region
    tenancy_ocid = var.tenancy_ocid
    user_ocid = var.user_ocid
    fingerprint = var.fingerprint
    private_key = var.private_key_path
}
