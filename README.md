# Rallly Selfhosting on Oracle Cloud Infrastructure

This repository contains a terraform template to deploy [Rallly](https://rallly.co) [Self-Hosted](https://support.rallly.co/self-hosting/introduction) on [OCI](https://www.oracle.com/cloud/)

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://console.eu-frankfurt-1.oraclecloud.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/gpoul/rallly-selfhosted-oci/releases/latest/download/rallly-stack.zip)

## Prerequisites

- Compartments already created in your tenancy
- SMTP Credential created and the secret stored in vault
- Public DNS Zone created for the FQDN that will be used
- Identity Domain that can be used to create a dynamic group in
- SSH Public Key

## Notes

- In OCI Resource Manager, `ad_name` is intentionally required so the availability domain is chosen explicitly in the stack UI.
- In direct Terraform usage, `ad_name` may be omitted and the configuration falls back to `data.oci_identity_availability_domain.ad`.
- The SPF DNS record is derived automatically for OCI commercial regions based on `region`.
- Rallly and Postgres container logs are written to `/var/log/rallly` on the boot volume and ingested into OCI Logging through the Custom Logs Monitoring plugin.
