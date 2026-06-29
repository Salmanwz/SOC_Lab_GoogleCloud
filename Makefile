.PHONY: init plan apply destroy fmt validate refresh

init:        ## Initialise providers + remote state
	tofu init

plan:        ## Preview changes
	tofu plan

apply:       ## Apply changes
	tofu apply

destroy:     ## Tear everything down
	tofu destroy

fmt:         ## Format all .tf files
	tofu fmt -recursive

validate:    ## Validate configuration
	tofu validate
