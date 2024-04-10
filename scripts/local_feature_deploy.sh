#!/usr/bin/env sh

### this script is used to run terraform apply for your local feature branch only. ###

test -f scripts/lib.sh || {
  echo "Please run the script from the root of the repository"
  exit 1
}
_command="apply"

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

while ! test -z ${1} ; do
  case "${1}" in
    -d|--destroy)
      _command="destroy" ;;
    -g|--generate)
      _command="plan -generate-config-out=generated-platform.tf" ;;
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
export TFDIR="terraform/dev"

if test "$_branch" = "prod" || test  "$_branch" = qa ; then
  echo "You are on a non-dev branch. Please checkout to your feature branch to run this script."
  exit 1
fi

## S3 state bucket configuration
## local aws default profile will be used
bucket_name="ping-terraform-demo"
region="us-west-1"
key="dev/${_branch}/terraform.tfstate"

## terraform init
terraform -chdir="${TFDIR}" init -migrate-state \
  -backend-config="bucket=${bucket_name}" \
  -backend-config="region=${region}" \
  -backend-config="key=${key}"

## terraform apply

echo "Running terraform apply for branch: ${_branch}, You will be prompted to enter the required variables."

export TF_VAR_pingone_environment_name="${_branch}"

terraform -chdir="${TFDIR}" ${_command}

