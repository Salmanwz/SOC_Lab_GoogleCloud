.PHONY: init plan apply destroy fmt validate

# Load .env (if present) and map secrets to their TF_VAR_ names, so targets
# pick them up automatically — no manual `export` each shell session.
# `.env` uses TS_AUTHKEY; Terraform wants TF_VAR_ts_authkey.
LOAD_ENV = set -a; [ -f .env ] && . ./.env; set +a; [ -n "$$TS_AUTHKEY" ] && export TF_VAR_ts_authkey="$$TS_AUTHKEY";

init:        ## Initialise providers + remote state
	tofu init

plan:        ## Preview changes
	@$(LOAD_ENV) tofu plan

apply:       ## Apply changes
	@$(LOAD_ENV) tofu apply

destroy:     ## Tear everything down
	@$(LOAD_ENV) tofu destroy

fmt:         ## Format all .tf files
	tofu fmt -recursive

validate:    ## Validate configuration
	tofu validate
