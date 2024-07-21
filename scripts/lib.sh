#!/usr/bin/env sh

## this holds the common functions used by other scripts ####

checkVars() {
  for var in \
  "${TF_VAR_pingone_client_region}" \
  "${TF_VAR_pingone_client_environment_id}" \
  "${TF_VAR_pingone_client_id}" \
  "${TF_VAR_pingone_client_secret}" \
  "${TF_VAR_pingone_environment_type}" \
  "${TF_VAR_pingone_davinci_admin_username}" \
  "${TF_VAR_pingone_davinci_admin_password}" \
  "${TF_VAR_pingone_davinci_admin_environment_id}" \
  "${TF_VAR_pingone_license_id}" \
  "${AWS_ACCESS_KEY_ID}" \
  "${AWS_SECRET_ACCESS_KEY}" \
  "${TF_VAR_tf_state_bucket}" \
  "${TF_VAR_tf_state_region}" \
  "${TF_VAR_tf_state_key_prefix}" ; do
    if [ -z "${var}" ]; then
      echo "Please set the required environment variables: 
      TF_VAR_pingone_region
      TF_VAR_pingone_environment_id
      TF_VAR_pingone_client_id
      TF_VAR_pingone_client_secret
      TF_VAR_pingone_environment_type
      TF_VAR_pingone_davinci_admin_username
      TF_VAR_pingone_davinci_admin_password
      TF_VAR_pingone_davinci_admin_environment_id
      TF_VAR_pingone_license_id
      AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY
      TF_VAR_tf_state_bucket
      TF_VAR_tf_state_region
      TF_VAR_tf_state_key_prefix"
      exit 1
    fi
  done
}