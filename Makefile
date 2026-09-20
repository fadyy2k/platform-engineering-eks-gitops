.PHONY: fmt validate plan k8s-check

fmt:
	terraform -chdir=infra fmt -recursive

validate:
	terraform -chdir=infra init -backend=false
	terraform -chdir=infra validate

plan:
	terraform -chdir=infra plan

k8s-check:
	docker run --rm -v "$$(pwd):/work" -w /work ghcr.io/yannh/kubeconform:v0.6.7 -strict -summary -ignore-missing-schemas apps platform
