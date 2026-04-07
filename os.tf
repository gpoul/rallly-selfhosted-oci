data "oci_objectstorage_namespace" "os_namespace" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "deploy_bucket" {
  compartment_id = var.compartment_ocid
  name           = "${local.resource_name_prefix}-deploy-bucket"
  namespace      = data.oci_objectstorage_namespace.os_namespace.namespace
}

resource "oci_objectstorage_object" "docker-compose" {
  bucket    = oci_objectstorage_bucket.deploy_bucket.name
  content   = templatefile("./objstore/docker-compose.yml", { rallly-version = var.rallly-container-tag })
  namespace = oci_objectstorage_bucket.deploy_bucket.namespace
  object    = "deploy/docker-compose.yml"
}

resource "oci_objectstorage_object" "podman-service" {
  bucket    = oci_objectstorage_bucket.deploy_bucket.name
  content   = file("./objstore/podman-compose.service")
  namespace = oci_objectstorage_bucket.deploy_bucket.namespace
  object    = "deploy/podman-compose.service"
}
