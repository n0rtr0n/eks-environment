# SSO and SCIM with Okta

Here, we leverage Okta as an identity provider to access to our internal resources. This provides the following benefits:

* Drastically reduces the number of credentials to manage by establishing trust relationships between our identity provider and the various service providers
* Allows us to build and/or configure SAML2 or OIDC SSO to our services and apps
* SCIM-based account provisioning/deprovisioning for lifecycle management
* Gates access based on context or attributes (i.e. device trust or group assignment)
* Easy way to configure and test various permission sets
* Single source of truth for human identities in our system
* Manage many of the resources in Terraform

## Setup

### Create an Okta account

Although Okta is a paid product, a free tier is offered for developers, with limitations on the number of users and applications you may create. If you do not already have an Okta tenant, sign up for one at [https://developer.okta.com/](https://developer.okta.com/) using a work email.

### Create client credentials for Terraform

Use the [current instructions provided by Okta](https://developer.okta.com/docs/guides/terraform-enable-org-access/main/) to create a set of client credentials for use by Terraform. In short:

* Create a new App with the type "API Services"
* Grant the newly created app the appropriate scopes (see following section)
* Grant the newly created app the "Organization Administer" and "Application Administer" roles
* Change the Client Credentials to use Public Key / Private Key as the Client authentication method
* Generate a new key, and securely store the private key from this step
* Note the client id and key id for configuration in a later step

### Configure Terraform app scopes

The following scopes are needed by the Terraform app:
```
okta.apps.manage
okta.apps.read
okta.groups.manage
okta.groups.read
```

### Configure local environment for Terraform

In the `live/sso/okta` directory, create a file name `.env` and configure the following values:
```
OKTA_ORG_NAME="<name/id of Okta tenant>"
OKTA_BASE_URL="okta.com"
OKTA_API_CLIENT_ID="<client id from app created in previous step>"
OKTA_API_PRIVATE_KEY_ID="<key id from app created in previous step>"
```

In the same directory, create a file name `client_secret_key.pem`. The content of this file will be the private key created in the previous step.

These files are added to the .gitignore and should not be committed to the repository.


## SSO for AWS

### Enable AWS IAM Identity Center

In AWS, AWS IAM Identity Center must be enabled in order to configure Okta as an identity provider for SSO.

### Set up SAML+SCIM app in Okta (AWS IAM Identity Center)

In Okta, enable the [AWS IAM Identity Center](https://www.okta.com/integrations/aws-iam-identity-center/) app integration. Follow the [setup instructions](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-AWS-Identity-Manager-Center.html) to configure SAML2 for this integration in Okta and AWS.

### Set up identity source in AWS IAM Identity Center

Follow the steps from [this guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/gs-okta.html), starting from Step 3, to enable automated provisioning, generate an API token, and configure the AWS IAM Identity Center app in Okta with this token.

### Configure Okta

This Terraform code will manage the creation of the groups and their assignment to the AWS SSO application. However, users must still be created manually, and assigned to the appropriate group, in order for them to be able to use SSO for AWS.

### Configure Push Groups

While the creation of groups can be managed by Terraform, automatically syncing the groups and memberships is still a manual process. The Okta Terraform provider does not currently include a way to manage Push Groups, per [this issue](https://github.com/okta/terraform-provider-okta/issues/312).

Fortunately, Push Groups can be configured to automatically sync Okta Groups with groups in the service provider based on rules (prefix, specific name, etc.). Navigate to the application details and configure the Push Groups within the "Push Groups" tab.

## Usage

Navigate to the `live/sso/okta` directory and run `./provision_okta.sh`. The environment configuration will automatically be applied. You will have an opportunity to review the changes.
