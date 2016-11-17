
These are some notes from the pairing session with Phillip Bailey, Diogo Lemos and Yohan Fernando.
These notes and FIXMEs were gathered when following instructions on the [Initial Setup](https://github.com/DigitalInnovation/bosh-concourse-setup/blob/master/docs/setup.md).

## Notes
----


1. Git clone https://github.com/DigitalInnovation/bosh-concourse-setup.git

2. Create local branch

3. Update `terraform/terraform.tfvars`
    - `boshers` - means source IPs that will interact with Bosh director (i.e. Alicudi, trasimeno, saline ..etc)

4. Validate the Assumptions:
    - Route53 zone in AWS
        1. Go to R53 in AWS Test Account
        2. Check available hosted zones
        3. Note down the zone id
        4. Note down the cert arn
    - EC2 SSH Keypair
        1. created a key pair with name `boshconcourse`

5. To setup a new stack from scratch the you need to create a S3 bucket to store the `tfstate` and give the bucket name in the `Makefile` so that it can be set in `terraform remote config`.  

  ```
  .terraform/terraform.tfstate:
     terraform remote config \
       -backend=S3 \
       -backend-config="<GIVE_BUCKET_NAME>" \
       -backend-config="key=terraform.tfstate" \
       -backend-config="region=eu-west-1" \
       -backend-config="encrypt=true" \
       -backend-config="acl=private”
  ```

5. Comment the unwanted resource records in the `dns.tf`

6. Run `make plan` and if it works `make apply`


## FIXMEs and things we thought that could be improved
---

[ ] `IMPROVEME` : How to run the `Makefile`  file with `sts:assumerole` credentials.

[ ] `FIXME` : Add a `make destroy` task to `Makefile`. This helps if you stopped the make apply halfway and need to cleanup the mess.
```
destroy: ## Plan, display and store that which would be needed to bring the infra up to date
		terraform destroy -var-file=$(TF_VARS) $(RESOURCES)/
```

[ ] `FIXME` : Pick up `zone_id` from `terraform/terraform.tfvars`.
Change `zone_id = "${aws_route53_zone.dachs-dog.zone_id}"` to `zone_id = "${var.ci_dns_zone_id}"`

[ ] `FIXME` : Rather than manually running the following command add that into the `Makefile` as a task. This will pick the correct `tfstate` path  in the respective `.sh` script.
```
yml2env vars/cloud_vars.yml ./bin/make_manifest_bosh-init.sh
```

[ ] `FIXME` : Login to the AWS console and get correct AZ based on the where the subnets were created initially by terraform. Set the correct value to `AWS_AZ` in `cloud_vars.yml` so that
`yml2env vars/cloud_vars.yml ./bin/make_manifest_bosh-init.sh` will not error.

[ ] `FIXME` : Define bosh director username in README for `bosh target`

[ ] `FIXME` : Remove `Remember to set your chosen AZ and the subnet-id output by terraform in aws-cloud.yml`

[ ] `FIXME`: Update README. `vm_types` on `compilation` section, should refer to something defined in VM types section defined in the `cloud-config`.
  ```
  compilation:
    workers: 5
    reuse_compilation_vms: true
    az: z1
    vm_type: large
    network: default
  ```

[ ] `FIXME` : Add `DISK_TYPE` env var to `concourse_vars.yml`


[ ] `FIXME` : Terraform creates two subnets and it can get created in different AZ when setting the cloud-config. However the  concourse manifest expects the subnet  in the same AZ. Following error was encountered during `bosh deploy`

```
can't use multiple availability zones: subnet in eu-west-1a, VM in eu-west-1c (00:00:19)
  Failed creating missing vms > worker/0 (0465491d-a2cb-4855-b804-9ad793664000): can't use multiple availability zones: subnet in eu-west-1a, VM in eu-west-1c (00:00:19)
  Failed creating missing vms > worker/1 (34d8ea0b-ef58-46f8-bec6-3d6ebdd3c642): can't use multiple availability zones: subnet in eu-west-1a, VM in eu-west-1c (00:00:19)
  Failed creating missing vms > db/0 (58c5d321-aa5d-47e0-b848-0e8865a3bc59): can't use multiple availability zones: subnet in eu-west-1a, VM in eu-west-1c (00:00:19)
  Failed creating missing vms (00:00:19)
```
