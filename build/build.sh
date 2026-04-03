#!/bin/bash

package_file="rallly-stack.zip"
rm -vf $package_file

set -euxo pipefail

zip -r $package_file *.tf *.yaml userdata/* objstore/*
