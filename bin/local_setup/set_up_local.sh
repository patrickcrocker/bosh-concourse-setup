#!/bin/bash
set -euo pipefail

# Generate bosh manifest
./bin/make_manifest_bosh-init.sh

# Get EIP of bosh director
cd .terraform/
export EIP=$(terraform output eip)
cd ../

# Target bosh director
./bin/local_setup/bosh_target.exp

# Generate cloud config
./bin/make_cloud_config.sh

# Generate concourse manifest
./bin/make_manifest_concourse.sh

# Set deployment in bosh to be concourse
bosh deployment concourse.yml
