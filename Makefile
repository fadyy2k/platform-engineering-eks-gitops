TF_ENV ?= dev
BACKEND_FILE := environments/$(TF_ENV).backend.hcl
VAR_FILE := environments/$(TF_ENV).tfvars.example

.PHONY: fmt validate bootstrap-init bootstrap-plan bootstrap-apply backend init plan apply k8s-check demo-test reliability-test game-day backup-restore-smoke policy-test operations-test preflight local-runtime-verify

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

policy-test:
	docker run --rm -v "$$(pwd):/repo" -w /repo ghcr.io/kyverno/kyverno-cli:v1.19.1 test security/kyverno/tests/digest --require-tests
	docker run --rm -v "$$(pwd):/repo" -w /repo ghcr.io/kyverno/kyverno-cli:v1.19.1 test security/kyverno/tests/signature --registry --require-tests

reliability-test:
	docker run --rm -v "$$(pwd):/work" mikefarah/yq:4.53.6 '{"groups": .spec.groups}' /work/reliability/manifests/platform-demo-rules.yaml > /tmp/platform-demo.rules.yaml
	docker run --rm --entrypoint /bin/promtool -v /tmp:/rules prom/prometheus:v3.14.0 check rules /rules/platform-demo.rules.yaml
	docker run --rm --entrypoint /bin/promtool -v /tmp:/rules -v "$$(pwd):/work" -w /work/reliability/tests prom/prometheus:v3.14.0 test rules platform-demo-rules-test.yaml

game-day:
	./scripts/game-day.sh pod-failure

backup-restore-smoke:
	./scripts/backup-restore-smoke.sh

operations-test:
	docker run --rm -v "$$(pwd):/work" mikefarah/yq:4.53.6 '{"groups": .spec.groups}' /work/cost/monitoring/opencost-budget-rule.yaml > /tmp/opencost-budget.rules.yaml
	docker run --rm --entrypoint /bin/promtool -v /tmp:/rules prom/prometheus:v3.14.0 check rules /rules/opencost-budget.rules.yaml
	docker run --rm --entrypoint /bin/promtool -v /tmp:/rules -v "$$(pwd):/work" -w /work/cost/tests prom/prometheus:v3.14.0 test rules opencost-budget-rule-test.yaml

preflight:
	./scripts/preflight.sh --local

local-runtime-verify:
	./scripts/local-runtime-verify.sh
