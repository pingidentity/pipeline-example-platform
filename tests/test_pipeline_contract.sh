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

grep -q '^  create:$' .github/workflows/push.yml
grep -Fq -- "- 'terraform/**'" .github/workflows/push.yml
grep -Fq -- "- 'scripts/**'" .github/workflows/push.yml
grep -Fq "github.event_name == 'create'" .github/workflows/push.yml
test "$(grep -Fc "github.event.ref != 'qa'" .github/workflows/push.yml)" -ge 4
test "$(grep -Fc "github.event.ref != 'prod'" .github/workflows/push.yml)" -ge 4
grep -q "github.event.head_commit.message || ''" .github/workflows/push.yml
grep -q 'EVENT_REF:.*github.event.ref || github.ref' .github/workflows/push.yml
grep -q '_branch="${_event_ref#refs/heads/}"' .github/workflows/push.yml
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
