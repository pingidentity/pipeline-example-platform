#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "${ROOT}"

# The local check must run fmt, lint and validate. The template keeps trivy in
# devcheck (re-evaluation tracked in issue #39); assert it is still wired.
devcheck=$(make -n devcheck)
test "$(printf '%s\n' "${devcheck}" | grep -c 'tflint --recursive')" -eq 1
test "$(printf '%s\n' "${devcheck}" | grep -c 'trivy config')" -eq 1
test "$(printf '%s\n' "${devcheck}" | grep -c 'terraform fmt -recursive -check')" -eq 1
test "$(printf '%s\n' "${devcheck}" | grep -c 'terraform -chdir=./terraform validate')" -eq 1

# Workflow contracts: no floating scanner/tool references or interactive Terraform.
! grep -R -n -E '@master|tflint_version:[[:space:]]*latest' .github/workflows
! grep -R -n -E 'terraform -chdir=.* (init|plan|apply|destroy)( |$)' .github/workflows | grep -v -- '-input=false'

# Create-event provisioning contract: a dedicated provision job stands up the
# feature environment; all other jobs are push-only; dependabot branches are
# excluded everywhere.
grep -q "github.event_name == 'create'" .github/workflows/push.yml
grep -q "github.event.ref != 'qa'" .github/workflows/push.yml
grep -q "github.event.ref != 'prod'" .github/workflows/push.yml
grep -q "startsWith(github.event.ref, 'dependabot/')" .github/workflows/push.yml
grep -Fq -- "'!dependabot/**'" .github/workflows/push.yml
grep -q 'name: Create Feature Environment' .github/workflows/push.yml
grep -q 'github.ref_type == '\''branch'\''' .github/workflows/push.yml
grep -q 'github.event.ref_type == '\''branch'\''' .github/workflows/prune.yml
! grep -q 'EVENT_REF' .github/workflows/push.yml

# No deprecated DaVinci user-based credentials anywhere.
! grep -R -q 'TF_VAR_pingone_davinci_admin_username\|TF_VAR_pingone_davinci_admin_password\|TF_VAR_pingone_davinci_admin_region\|TF_VAR_pingone_davinci_user_group_id' scripts secretstemplate .github/workflows README.md

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
