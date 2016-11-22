.PHONY: infra plan apply tf-apply clean mrproper help init-state
.DEFAULT_GOAL := help

AWS_PROFILE         ?= default
AWS_DEFAULT_REGION  ?= eu-west-1
NOW           	    := $(shell date +"%Y%m%d-%H%M%S")
TF_RESOURCES 	    := terraform
TF_STATE_INIT_PATH  := $(TF_RESOURCES)/init/.terraform
TF_STATE_VAR_FILE   := vars/terraform_state.yml
TF_STATE_S3_BUCKET  ?= $(shell sed 's|.*:[[:space:]]*||g' $(TF_STATE_VAR_FILE))
TF_STATE_S3_KEY     := terraform.tfstate

TF_VARS       	    ?= $(TF_RESOURCES)/terraform.tfvars
TF_STATE_PATH 	    := .terraform/terraform.tfstate
TF_FILES            := $(wildcard $(TF_RESOURCES)/*.tf $(TF_STATE_PATH) $(TF_VARS))
TF_PLAN             := plan.out

export AWS_PROFILE AWS_DEFAULT_REGION

infra: plan apply ## Do whatever's needed to bring the infra up to date

plan: $(TF_PLAN) ## Plan, display and store that which would be needed to bring the infra up to date
$(TF_PLAN): $(TF_STATE_PATH) $(TF_FILES)
	terraform plan -out $(TF_PLAN) -var-file=$(TF_VARS) $(TF_RESOURCES)/

apply: $(TF_STATE_PATH) tf-apply clean ## Apply the current plan of operations to the infra, without replanning
tf-apply:
	terraform apply $(TF_PLAN)

show: ## Print what the current plan of operations would do, without replanning
	terraform show $(TF_PLAN)

clean: ## Archive the last plan
	mv $(TF_PLAN) .$(TF_PLAN).$(NOW)

mrproper: ## Remove all non-version-controlled files
	rm -f $(TF_STATE_PATH) $(TF_PLAN) .$(TF_PLAN).*

init-state: ## Create terraform remote state AWS s3 bucket
	@mkdir -p "$(TF_STATE_INIT_PATH)"
	-@terraform plan -detailed-exitcode -state="$(TF_STATE_INIT_PATH)/terraform.tfstate" -var state_s3_bucket="$(TF_STATE_S3_BUCKET)" -out $(TF_STATE_INIT_PATH)/$(TF_PLAN) $(TF_RESOURCES)/init/
	@terraform apply -state="$(TF_STATE_INIT_PATH)/terraform.tfstate" $(TF_STATE_INIT_PATH)/$(TF_PLAN) || rm -rf "$(TF_STATE_INIT_PATH)"

.terraform/terraform.tfstate:
	terraform remote config \
	  -backend=S3 \
	  -backend-config="bucket=$(TF_STATE_S3_BUCKET)" \
	  -backend-config="key=$(TF_STATE_S3_KEY)" \
	  -backend-config="region=$(AWS_DEFAULT_REGION)" \
	  -backend-config="encrypt=true" \
	  -backend-config="acl=private"

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
