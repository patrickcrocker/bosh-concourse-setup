Local Setup - Scripted so you don't have to worry
=================================================
Note that these steps assume the concourse is already deployed

## Prerequisites
- Install the [yml2env tool](https://github.com/EngineerBetter/yml2env)
- Install [terraform](https://www.terraform.io/intro/getting-started/install.html)
- Have AWS creds for the account the concourse is running in

## Setting up the local environment
Ensure you have an access key in ~/.aws/credentials with appropriate permissions. Take note of the key's group name (ie default).
```
AWS_PROFILE=<profile name> make setup
```
where `<profile name>` is the key's group name mentioned above.

## Overview of what is happening
* yml file containing necessary variables is fetched from S3
* terraform state is fetched from remote in S3
* The bosh, cloud, and concourse manifests are generated
* The bosh director is targeted and authenticated
