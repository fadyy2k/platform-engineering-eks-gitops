TF_ENV ?= dev
BACKEND_FILE := environments/$(TF_ENV).backend.hcl
VAR_FILE := environments/$(TF_ENV).tfvars.example

.PHONY: fmt validate bootstrap-init bootstrap-plan bootstrap-apply backend init plan apply k8s-check demo-test

fmt:
	terraform fmt -recursive infra bootstrap

validate:
	terraform -chdir=infra init -backend=false -input=false
	terraform -chdir=infra validate
	terraform -chdir=bootstrap init -backend=false -input=false
	terraform -chdir=bootstrap validate

bootstrap-init:
	terraform -chdir=bootstrap init -input=false

bootstrap-plan: bootstrap-init
	terraform -chdir=bootstrap plan

bootstrap-apply: bootstrap-init
	terraform -chdir=bootstrap apply

backend:
	./scripts/render-backend-config.sh $(TF_ENV)

init:
	test -f infra/$(BACKEND_FILE) || (echo "missing infra/$(BACKEND_FILE); run 'make backend TF_ENV=$(TF_ENV)'" && exit 1)
	terraform -chdir=infra init -reconfigure -backend-config=$(BACKEND_FILE)

plan: init
	terraform -chdir=infra plan -var-file=$(VAR_FILE)

apply: init
	terraform -chdir=infra apply -var-file=$(VAR_FILE)

k8s-check:
	docker run --rm -v "$$(pwd):/work" -w /work ghcr.io/yannh/kubeconform:v0.6.7 -strict -summary -ignore-missing-schemas apps platform

demo-test:
	cd demo-app && go test ./... && go vet ./...
