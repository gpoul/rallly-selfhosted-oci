variable rallly-container-tag {
}

data "oci_objectstorage_namespace" "test_namespace" {
    compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "test_bucket" {
    compartment_id = var.compartment_ocid
    name = "rallly-deploy-bucket"
    namespace = data.oci_objectstorage_namespace.test_namespace.namespace
}

resource "oci_objectstorage_object" "test_object" {
    bucket = oci_objectstorage_bucket.test_bucket.name
    content = templatefile("./objstore/docker-compose.yml", { rallly-version = var.rallly-container-tag })
    namespace = oci_objectstorage_bucket.test_bucket.namespace
    object = "deploy/docker-compose.yml"
}

resource "oci_objectstorage_object" "podman-service" {
    bucket = oci_objectstorage_bucket.test_bucket.name
    content = file("./objstore/podman-compose.service")
    namespace = oci_objectstorage_bucket.test_bucket.namespace
    object = "deploy/podman-compose.service"
}

