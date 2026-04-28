variable "tenancy_ocid" {
}

variable "current_user_ocid" {
}

variable "fingerprint" {
  type     = string
  nullable = true
  default  = null
}

variable "private_key_path" {
  type     = string
  nullable = true
  default  = null
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

variable "baseline_ocpu_utilization" {
  type    = string
  default = "BASELINE_1_1"
  validation {
    condition     = var.baseline_ocpu_utilization == "BASELINE_1_1" || var.baseline_ocpu_utilization == "BASELINE_1_2" || var.baseline_ocpu_utilization == "BASELINE_1_8"
    error_message = "The baseline_ocpu_utilization must be BASELINE_1_1, BASELINE_1_2, or BASELINE_1_8"
  }
}

variable "ad_name" {
  default = null
}

variable "ssh_public_key" {
  default = ""
}

variable "fqdn" {
}

variable "identity_domain" {
}

variable "rallly_smtp_credential_username" {
}

variable "rallly_smtp_credential_secret_ocid" {
}

variable "rallly_smtp_credential_compartment" {
}

variable "allowed_emails" {
  type    = string
  default = ""
}

variable "rallly-container-tag" {
}
