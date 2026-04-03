variable "tenancy_ocid" {
}
variable "current_user_ocid" {
}
variable "fingerprint" {
  type = string
  nullable = true
  default = null
}
variable "private_key_path" {
  type = string
  nullable = true
  default = null
}
variable "compartment_ocid" {
}
variable "region" {
}
variable "instance_shape" {
  type = map(any)
  default = {
    "instanceShape" = "VM.Standard.E5.Flex"
    "ocpus"         = 2
    "memory"        = 4
  }
  description = "A shape is a template that determines the number of OCPUs, amount of memory, and other resources allocated to a newly created instance"
}
variable "ssh_public_key" {
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHasHu9ZLFZsmef78hfr7z/BsXJLSxVwSmxVFLScA/vk gpoul@Gerhards-MacBook-Air.local"
}

provider "oci" {
    region = var.region
    tenancy_ocid = var.tenancy_ocid
    user_ocid = var.current_user_ocid
    fingerprint = var.fingerprint != null ? var.fingerprint : null
    private_key = var.private_key_path != null ? var.private_key_path : null
}
