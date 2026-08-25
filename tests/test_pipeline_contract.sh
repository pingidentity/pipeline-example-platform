#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "${ROOT}"

# The local check must execute the security scan, not merely validate the binary.
devcheck=$(make -n devcheck)
test "$(printf '%s\n' "${devcheck}" | grep -c 'trivy config')" -eq 1

# Workflow contracts: no floating scanner/tool references or interactive Terraform.
! grep -R -n -E '@master|tflint_version:[[:space:]]*latest' .github/workflows
! grep -R -n -E 'terraform -chdir=.* (init|plan|apply|destroy)( |$)' .github/workflows | grep -v -- '-input=false'

grep -q 'github.ref_type == '\''branch'\''' .github/workflows/push.yml
grep -q 'github.event.ref_type == '\''branch'\''' .github/workflows/prune.yml
grep -q 'permissions:' .github/workflows/push.yml
grep -q 'permissions:' .github/workflows/pull_request.yml
grep -q 'permissions:' .github/workflows/prune.yml

# Generated/runtime files are ignored; authored Terraform remains visible.
for path in tfplan plan.tfplan terraform/terraform.tfplan tfvars terraform/terraform-debug.log; do
  git check-ignore -q "${path}"
done
git check-ignore -q .polaris/
! git check-ignore -q terraform/example.tf

test -f terraform/.terraform.lock.hcl
! git check-ignore -q terraform/.terraform.lock.hcl

sh -n scripts/lib.sh scripts/local_feature_deploy.sh

echo 'pipeline contract checks passed'
