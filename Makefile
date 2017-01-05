.PHONY: infra plan apply tf-apply setup setup-local clean mrproper help
.DEFAULT_GOAL := help

AWS_PROFILE ?= Default
NOW         := $(shell date +"%Y%m%d-%H%M%S")
RESOURCES   := terraform
TF_VARS     ?= $(RESOURCES)/terraform.tfvars
STATE       := .terraform/terraform.tfstate
TF_FILES    := $(wildcard $(RESOURCES)/*.tf $(STATE) $(TF_VARS))
PLAN        := plan.out
export AWS_PROFILE

infra: plan apply ## Do whatever's needed to bring the infra up to date

plan: $(PLAN) ## Plan, display and store that which would be needed to bring the infra up to date
$(PLAN): $(STATE) $(TF_FILES)
	terraform plan -out $(PLAN) -var-file=$(TF_VARS) $(RESOURCES)/

apply: $(STATE) tf-apply clean ## Apply the current plan of operations to the infra, without replanning
tf-apply:
	terraform apply $(PLAN)

show: ## Print what the current plan of operations would do, without replanning
	terraform show $(PLAN)

setup: $(STATE) setup-local ## Build local environment for the dachs concourse.  Requires AWS_PROFILE=<credentials group>
setup-local:
	aws s3 cp --region eu-west-1 s3://dachs-setup-variables/state_vars.yml vars/state_vars.yml
	yml2env vars/state_vars.yml ./bin/local_setup/set_up_local.sh

clean: ## Archive the last plan
	mv $(PLAN) .$(PLAN).$(NOW)

mrproper: ## Remove all non-version-controlled files
	rm -f $(STATE) $(PLAN) .$(PLAN).*

.terraform/terraform.tfstate:
	terraform remote config \
	  -backend=S3 \
	  -backend-config="bucket=dachs-terraform" \
	  -backend-config="key=terraform.tfstate" \
	  -backend-config="region=eu-west-1" \
	  -backend-config="encrypt=true" \
	  -backend-config="acl=private"

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
