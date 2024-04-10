# Ping Platform Example Pipeline

The intention of this repo is to present a simplified reference of how a CICD pipeline could look for Ping Identity solutions. The configuration managed in this covers "platform" components that are complementary to the [infrastructure](https://github.com/pingidentity/pipeline-example-infrastructure) and [application](https://github.com/pingidentity/pipeline-example-application) example pipeline repositories. 

**Infrastructure** - Components dealing with deploying software onto self-managed Kubernetes infrastructure and any configuration that must be delivered directly via the filesystem.
Platform

**Platform** - Components dealing with deploying configuration to self-managed or hosted services that will be shared and leveraged by upstream applications.

**Application** - Delivery and configuration of a client application that relies on core services from Platform and Infrastructure.

The use-cases and features shown in this repository are an implementation of the guidance provided from Ping Identity's "[Terraform Best Practices](https://terraform.pingidentity.com/best-practices/)" and "[Getting Started with Configruation Promotion at Ping](https://terraform.pingidentity.com/getting-started/configuration-promotion/)" documents. The use-cases and features shown within a GitOps process of developing and delivering a new feature are:

- Feature Request Template
- On-demand development environment deployment
- Building feature in development environment (PingOne UI)
- Extracting feature configuration to be stored as code
- Validating extracted configuration from developer perspective
- Validating suggested configuration adheres to contribution guidelines
- Review process of suggested change. 
- Approval of change and automatic deployment into higher environments 

## Prerequisites

To be successful in re-creating the use-cases supported by this pipeline, there are initial steps that should be completed prior to configuring this repository:

- A [PingOne trial](https://docs.pingidentity.com/r/en-us/pingone/p1_start_a_pingone_trial) or paid account configured for [PingOne Terraform access](https://terraform.pingidentity.com/getting-started/pingone/) and [DaVinci Terraform](https://terraform.pingidentity.com/getting-started/davinci/) access guidelines.
> Note - For PingOne, this means you should have credentials for a worker app residing in the "Administrators" environment that has organization-level scoped roles. For DaVinci, this means you should have credentials for a user in a non-"Administrators" environment that is part of a group specifically intended to be used by command-line tools or APIs with environment-level scoped roles. This demo will add roles to the DaVinci command-line group and will fail if roles are not scoped properly.
- An [AWS trial](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all) or paid account 
- Terraform CLI v1.6+
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [gh](https://cli.github.com/) the Github CLI utility

## Development Lifecycle Diagram

The use-cases in this repository follow the flow in this diagram:

![SDLC flow](./img/generic-pipeline.png "Development Flow")

## Before You Start

There are a few items to configure before using the repository effectively.

### AWS S3 Bucket for Terraform State Storage

In order to avoid committing private information within terraform state to git, and to have an efficient developer experience, it is a best practice to use a [remote backend for Terraform state](https://developer.hashicorp.com/terraform/language/settings/backends/remote). As such, this example uses AWS S3 for remote state management. 

The default information for this repository is:

Bucket name = `ping-terraform-demo`
Bucket region = `us-west-1`

> Note: To use values other than the default, find and replace those text strings in the repo.

Details on appropriate permissions for the S3 bucket and corresponding AWS IAM user can be found on [Hashicorp's S3 Backend documentation](https://developer.hashicorp.com/terraform/language/settings/backends/s3)


### Github CLI and Github Actions Secrets

#### Github CLI

The github cli: `gh` will need to be configured for your repository. Run the command **gh auth login** and follow the prompts.  You will need an access token for your Github account as instructed:
```
gh auth login

? What account do you want to log into? GitHub.com
? You're already logged into github.com. Do you want to re-authenticate? Yes
? What is your preferred protocol for Git operations? HTTPS
? Authenticate Git with your GitHub credentials? Yes
? How would you like to authenticate GitHub CLI? Paste an authentication token
Tip: you can generate a Personal Access Token here https://github.com/settings/tokens
The minimum required scopes are 'repo', 'read:org', 'workflow'.
? Paste your authentication token: ****************************************
- gh config set -h github.com git_protocol https
✓ Configured git protocol
✓ Logged in as <User>
```

#### Github Actions Secrets

The Github pipeline actions will depend on sourcing some secrets as ephemeral environment variables. To prepare the secrets in the repository:

First:

```
cp secretstemplate localsecrets
```
And fill in `localsecrets` accordingly. 

> Note, `secretstemplate` is intended to be a template file, `localsecrets` is a file that contains credentials but is part of .gitignore and should never be committed into the repository.

Then run the following to upload localsecrets to Github:

```
_secrets="$(base64 -i localsecrets)"
gh secret set --app actions TERRAFORM_ENV_BASE64 --body $_secrets
unset _secrets
```

### Deploy Prod and QA

The final step before creating new features is to deploy the static environments `prod` and `qa`. 

At the creation of the repository, a Github Action should have triggered and failed. To deploy prod, click "Re-run jobs" and choose "Re-run all jobs". If your secrets are configured correctly, this should result in the successful deployment of a new environment named "prod" in your PingOne account.

To deploy the `qa` environment, simply create and push a new branch from prod with the name `qa`:

```
git checkout prod
git pull origin prod
git checkout -b qa
git push origin qa
```


## Feature Development

Now that the repository and pipeline are configured, the standard git flow can be followed. To experience the developer's perspective, the following steps will revolve around the use-case of adding a new OIDC web application configuration into the PingOne prod environment.

1. Create an GitHub Issue for a new feature request via the UI. GitHub Issue Templates help ensure the requestor provides appropriate information on the issue. Note, your GitHub Issue name will be used to create the PingOne environment.

<!-- image -->

2. Click "Create a branch" and choose "Checkout Locally" for GitHub to create a development branch and PingOne environment on your behalf.

3. Once the Github Actions pipeline completes, log in to your PingOne account with a user that has appropriate roles. This may be the organization admin that you signed up with the trial for, or a development user if you have configured roles for it. PingOne should show a new environment with a name similar to your GitHub issue title.

4. Build the requested configuration by navigating into the environment -> "Applications" -> "Applications" -> Click the blue "+" -> Name the application "my-awesome-oidc-web-app" and select OIDC web app for Application Type -> "Save" -> Toggle the enable switch. On the screen where the application is enabled, the environment id and application client id will also be shown. Capture these for use in the import process. 

5. Typically the next step would be to provide the application details to the developer team for testing, this is skipped in the example for brevity.

6. After the application creation is "tested" manually, the new configuration is added to the terraform configuration. This will happen in a few steps, starting with creating and testing the configuration in the `./terraform/dev` folder. 

  a. Terraform provides a [tool to help generate configuration](https://developer.hashicorp.com/terraform/language/import) for resources built directly in the environment. To leverage this tool as a developer, an import block will be added to `./terraform/dev/imports.tf`. Note, this file is not intended to be committed to git and is included in .gitignore. Add lines similar to the following in `./terraform/dev/imports.tf`.

```hcl
import {
  to = pingone_application.my_awesome_oidc_web_app
  id = "environment_id/client_id"
}
```

> Note, to understand what value should be used in the id attribute of any resource, the developer should refer to that resources documentation on registry.terraform.io

  b. Next run the generate command to generate output. In this repo, the generate command is wrapped in the deploy script:

```
./scripts/local_feature_deploy.sh --generate
```

This will create a file with the generated output at `./terraform/dev/generated-platform.tf`

However, the command line should have also returned an error similar to the following:

```log
Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: expected refresh_token_duration to be in the range (60 - 2147483647), got 0
│ 
│   with pingone_application.my_awesome_oidc_web_app,
│   on generated-platform.tf line 22:
│   (source code not available)
│ 
╵
╷
│ Error: expected refresh_token_rolling_duration to be in the range (60 - 2147483647), got 0
│ 
│   with pingone_application.my_awesome_oidc_web_app,
│   on generated-platform.tf line 23:
│   (source code not available)
```

Terraform's import feature may frequently return errors due to complications with resource schema's. When this occurs the developer is typically able to correct the issue by reading the error. 

  c. To resolve the error, two attributes in the generated configuration must be updated: 

```
    refresh_token_duration                             = 0
    refresh_token_rolling_duration                     = 0
```
-->
```
    refresh_token_duration                             = 60
    refresh_token_rolling_duration                     = 60
```

  d. Once the generated configuration is corrected, run the local deploy script again to import the resource into terraform's managed state:

```
./scripts/local_feature_deploy.sh   

Initializing the backend...
Initializing modules...
... trimmed extra lines ...

            support_unsigned_request_object                    = false
            token_endpoint_authn_method                        = "CLIENT_SECRET_BASIC"
            type                                               = "WEB_APP"
        }
    }

Plan: 1 to import, 0 to add, 1 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
```

  e. Accept the plan and allow it to complete. Once complete, the deploy script can be run again to confirm there are no missed changes and signal that this configuration is ready to move into the base module.

7. Copy the new configuration into the base module at `/terraform/pingone_platform.tf`. Note, because this configuration is general for each environment, the environment_id attribute must be updated accordingly. The final new resource should look similar to:

```hcl
resource "pingone_application" "my_awesome_oidc_web_app" {
  access_control_role_type = null
  description              = null
  enabled                  = true
  environment_id           = pingone_environment.target_environment.id
  hidden_from_app_portal   = false
  login_page_url           = null
  name                     = "my awesome oidc web app"
  tags                     = []
  oidc_options {
    additional_refresh_token_replay_protection_enabled = true
    allow_wildcards_in_redirect_uris                   = false
    grant_types                                        = ["AUTHORIZATION_CODE"]
    home_page_url                                      = null
    initiate_login_uri                                 = null
    jwks                                               = null
    jwks_url                                           = null
    par_requirement                                    = "OPTIONAL"
    par_timeout                                        = 60
    pkce_enforcement                                   = "OPTIONAL"
    post_logout_redirect_uris                          = []
    redirect_uris                                      = []
    refresh_token_duration                             = 60
    refresh_token_rolling_duration                     = 60
    refresh_token_rolling_grace_period_duration        = 0
    require_signed_request_object                      = false
    response_types                                     = ["CODE"]
    support_unsigned_request_object                    = false
    target_link_uri                                    = null
    token_endpoint_authn_method                        = "CLIENT_SECRET_BASIC"
    type                                               = "WEB_APP"
  }
}
```

8. A `git status` command should show the file changed with your new configuration:

```
git status                       
On branch 1-request-new-web-oidc-p1-app-for-my-awesome-oidc-app
Your branch is ahead of 'origin/1-request-new-web-oidc-p1-app-for-my-awesome-oidc-app' by 1 commit.
  (use "git push" to publish your local commits)

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   terraform/pingone_platform.tf

no changes added to commit (use "git add" and/or "git commit -a")
```

9. Before committing and pushing changes to GitHub, it is important to run the local development validations to ensure the proposed configuration meets the defined standards. In this case, those validates are called via `make devcheck`: 

```
make devcheck
==> Formatting Terraform code with terraform fmt...
==> Checking Terraform code with terraform fmt...
==> Validating Terraform code with terraform validate...
Success! The configuration is valid.

==> Checking Terraform code with tflint...
==> Checking Terraform code with trivy...
2024-04-10T00:34:09.630-0600    INFO    Misconfiguration scanning is enabled
2024-04-10T00:34:13.544-0600    INFO    Detected config files: 7
```

10. Now that the configuration is completely ready, git add, commit, and push the change to GitHub. This push to GitHub will trigger the "Feature Deploy Push" action. However, if you inspect the `Deploy` step, there should be no changed needed! This is because your local environment is using the same remote backend terraform state as the pipeline, so the pushed change to the feature branch is the same as running the local deploy script. 

> Note - From here, the configuration deployment should not include any more manual changes within the UI of higher environments. PingOne Administrators or Developers may have access to the UI, but it should be for reviewing changes rather than making changes. 

11. Open a Pull request for the feature branch to be merged into the qa branch. This pull request will trigger an action that runs validations similar to what occured in `make devcheck` as well as an important `terraform plan` command. The results of this terraform plan is what the reviewer of the pull request should put emphasis on. In this case, the plan should show one new resource would be created if the pull request is merged. 

12. Upon satisfaction with review, merge the pull request into the qa branch. This merge triggers an action that will deploy the new change.

13. Finally, to get the feature into the production environment, the same pull request, review, and merge process will occur. With the only difference being the change is merging the qa branch into the prod branch. 

14. Once the merge to prod is complete and is the issue is considered complete, the GitHub isssue can be closed and the development branch can be deleted. When the development branch is deleted, a GitHub Action will be triggered to delete the corresponding PingOne Environment leaving just the qa and prod environments relevant to this example remaining. 