#!/usr/bin/env sh
# Copyright © 2026 Ping Identity Corporation

set -eu

### this script is used to run terraform apply for your local feature branch only. ###

test -f scripts/lib.sh || {
  echo "Please run the script from the root of the repository"
  exit 1
}
_command="apply"
_generate=false

usage ()
{
cat <<END_USAGE
Usage: 
  This script is used to run terraform apply for your local feature branch only. 
  This script should be run from the root of the repository. 
  Terraform Secrets (\`localsecrets\` file) should be sourced and exported in the evironment

{options}
    where {options} include:
    -d, --destroy
      Run terraform destroy instead of apply
    -g, --generate
      Generate terraform resources from import blocks
END_USAGE
exit 99
}

exit_usage()
{
    echo "$*"
    usage
    exit 1
}

while [ "$#" -gt 0 ]; do
  case "${1}" in
    -d|--destroy)
      _command="destroy" ;;
    -g|--generate)
      _generate=true ;;
    -v|--verbose)
      set -x ;;
    -h|--help)
      exit_usage "" ;;
    *)
      exit_usage "Unrecognized Option" ;;
  esac
  shift
done

# shellcheck source=lib.sh
. scripts/lib.sh

checkVars

_branch=$(git rev-parse --abbrev-ref HEAD)
export TFDIR="terraform"

if test "$_branch" = "prod" || test  "$_branch" = qa ; then
  echo "You are on a non-dev branch. Please checkout to your feature branch to run this script."
  exit 1
fi

## S3 state bucket configuration
## local aws default profile will be used
## Specify the bucket name and region
if [ -z "${TF_VAR_tf_state_bucket}" ] || [ -z "${TF_VAR_tf_state_region}" ]; then
  echo "TF_VAR_tf_state_bucket or TF_VAR_tf_state_region is not set. Please set the appropriate variables in your localsecrets file."
  exit 1
fi
_bucket_name="${TF_VAR_tf_state_bucket}"
_region="${TF_VAR_tf_state_region}"
_key="${TF_VAR_tf_state_key_prefix}/dev/${_branch}/terraform.tfstate"

## terraform init
# -reconfigure (not -migrate-state): each branch has its own state key, and a
# new branch starts with empty state rather than inheriting the previously
# initialized branch's state. Migration would also prompt interactively,
# which -input=false forbids.
terraform -chdir="${TFDIR}" init -input=false -reconfigure \
  -backend-config="bucket=${_bucket_name}" \
  -backend-config="region=${_region}" \
  -backend-config="key=${_key}"

# Resolve the branch environment's ID from the branch Terraform state (falls
# back to the admin environment from localsecrets when the state has no
# output yet, e.g. before the first deploy).
_branch_environment_id=$(terraform -chdir="${TFDIR}" output -raw pingone_environment_id 2>/dev/null || true)
case "${_branch_environment_id}" in
  [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]-*) ;;
  *) _branch_environment_id="${TF_VAR_pingone_client_environment_id-}" ;;
esac
[ -n "${_branch_environment_id}" ] || {
  echo "Could not determine the environment ID: no branch state output and no TF_VAR_pingone_client_environment_id set." >&2
  exit 1
}

## terraform apply

echo "Running terraform apply for branch: ${_branch}, You will be prompted to enter the required variables."

export TF_VAR_pingone_environment_name="${_branch}"

if [ "${_generate}" = true ]; then
  TF_VAR_pingone_environment_id="${_branch_environment_id}" \
    terraform -chdir="${TFDIR}" plan -generate-config-out=generated-platform.tf
else
  TF_VAR_pingone_environment_id="${_branch_environment_id}" \
    terraform -chdir="${TFDIR}" "${_command}"
fi

