# EKS Environment

Playground for testing Terraform configurations for EKS.

***WARNING***
This environment will cost money!!! It is intended to be a disposable and temporary environment, so remember to run `./run.sh down -a` when it is not actively in use, in order to avoid a large AWS bill.

The environment features a complete example with the following resources and patterns:

* EKS cluster
* Github Actions CI/CD build pipeline
* Secrets Management with external-secrets-operator and SSM Parameter Store
* [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-how-it-works.html) for access to AWS resources
* IRSA where Pod Identities are not available, with OIDC from the EKS cluster to AWS 
* Various patterns of Terraform management
* [Tailscale subnet router](https://tailscale.com/kb/1019/subnets) for safer access to internal resources

## Pre-requisites

While these instructions are specific to a Mac environment with [Homebrew](https://brew.sh/), the dependencies are largely the same across any platform.

### Terraform >= 1.9

[tfenv](https://github.com/tfutils/tfenv) is the recommended way to manage versions of Terraform locally.

```
brew install tfenv
tfenv install 1.9.4
tfenv use 1.9.4
```

### AWS Account and AWS CLI

A priveleged AWS account is required in order to provision this infrastructure. Ensure that `awscli` is installed:

```
brew install awscli
```

It is recommended to *not* use the IAM credentials for the root user. Instead, create a privileged IAM account/role and configure the AWS CLI to use the IAM credentials, and (preferably) assume the privileged role instead of directly using the privileged IAM credentials. This is also beyond the scope of this repository. [aws-vault](https://github.com/99designs/aws-vault) may also be used to assist with this configuration.

```
aws configure
```

### Bash
The `./run.sh` script requires Bash.

### Custom Domain Name
In order to set up this ecosystem with a custom domain, a domain you control that is managed by Route 53 with a public hosted zone is required. This setup is beyond the scope of this repository.

## Setup

A script, `run.sh` is provided to assist with provisioning activities. Follow these instructions to get started:

1. *Configuration* - There are a few states that may require additional configuration prior to running a Terraform plan/apply cycle. For each of the following paths, create a `secrets.tfvars` file and customize the values. These files should not be checked into the repository, as they contain configuration that is specific to your environment:

*live/global/secrets.tfvars*
```
github_repo_name = "<github username>/<github repository name>" 
```
The default for the above is this repository, `n0rtr0n/eks-environment`, but change it to another if you have forked it.

*live/dev/eks-config/secrets.tfvars*
```
domain_name = "<your own domain>"
```

*live/dev/tailscale/subnet-router/secrets.tfvars*
```
ssh_public_key = "<your public ssh key>"
```

2. *Initialization* - Run the following command, which will initialize the global state, which includes an ECR registry, and the SSM Parameters required for certain resources:
```
./run.sh init -a
```

3. *Update SSM Parameters* - In AWS, update the values of the created SSM parameters to the correct production values, according to your setup. Placeholders are provisioned for the secrets when they are creatd in the previous step, so you will need the production values in order to proceed. 

4. *Provisioning* - When you are finished, run the following to provision the remaining resources:

```
./run.sh up -a
```

This step will create a VPC, an EKS cluster with node workers, an external secrets operator to synchronize the secrets we created in the init step to the EKS cluster, a monitoring and logging stack, and deploy a sample application (prime-generator-python) with a small GitHub Actions pipeline.

1. *SSO* - To connect an an identity provider for single sign-on, follow the guide at [https://github.com/n0rtr0n/eks-environment/tree/main/live/sso](https://github.com/n0rtr0n/eks-environment/tree/main/live/sso).

This state will be unaffected by de-provisioning the the infrastructure, and many of the steps in the guide require manual setup in AWS and Okta. 

### Options

`-a|--auto-approve` will automatically approve Terraform apply commands. Use only if you are confident that the configuration is correct.

`-s|--destroy-secrets` will additionally destroy the SSM Parameter resources from initial provisioning, which are preserved in order. Has no effect when used with `./run.sh up` or `./run.sh init`.

`-g|--destroy-global` will additionally destroy resources created from the init step in global state, including the ECR registry. Has no effect when used with `./run.sh up` or `./run.sh init`.


### Manual Provisioning

If manually provisioning resources from a specific state is desired, you may navigate to the corresponding state in the `live` directory and run `terraform apply`. Note, however, that it may depend on resources created in a separate state, so provisioning all resources with the script is recommended. Also note that some states may contain a `pre_deployment.sh`, `post_deployment.sh`, `pre_teardown.sh`, or `post_deployment.sh`. These scripts assist with the creation or deletion of any resources that are managed outside of Terraform, and should be run prior or after deployment or teardown, according to their name.

## Design Decisions

### Terraform State Management

In most cases, particularly for critical applications, Terraform state should be centrally managed and involve a locking mechanism to prevent simultaneous operations on the state from interfering with one another. When the number of developers scales beyond one, or the complexity reaches a certain threshold, this is almost a necessity. However, this repository is intended to contain relatively disposable infrastructure that can be spun up and down quickly, for the sake of demonstrating certain features. Most design decisions here are predicated on the idea that this is not intended to be a long-lived environment. State is stored locally, and references to state dependencies are based on relative paths. The state is not checked into the repository.

### Secrets Management

While Kubernetes has a mechanism to manage secrets, securely provisioning the secrets is another matter. The following options were evaluated:
1. Create secrets resources and store the values in the repository. This is obviously bad, because manifests do not include encryption by default.
2. Provision the k8s secrets manually or with an additional script. While more viable, updates to the secrets require re-provisioning, and any manual step is easily missed or forgotten.
3. [Sealed secrets](https://github.com/bitnami-labs/sealed-secrets). While this method provides a way to safely store encrypted values, even in a public repository, it requires the cluster to be available since it uses a certificate that is provisioned after cluster created. If the cluster is re-created, a new certificate will be generated, removing the ability to decrypt sealed secrets. Not a viable option for disposable infrastructure.
4. [External Secrets Operator](https://external-secrets.io/latest/). Within the cluster, k8s secrets are created / synchronized from an external source.

The last option, external secrets, was chosen for this demonstration. First, SSM Parameters are created and configured. Then, the external-secrets operator is installed in the EKS cluster. At the time it is installed, it is given an IRSA role with permissions to pull the secret value from SSM Parameter Store. At an interval that is specified for the secret, the Parameter Store value is synchronized with a k8s secret. This means that the k8s secret will automatically be updated without needing to re-provision the secret. This also allows a much more flexible secrets management path for SSM Parameter Store - access can be temporarily granted or restricted to multi-party authorization policies, without needing to directly touch the EKS cluster.

### SSM Parameter Store vs Secrets Manager

In many cases, AWS Secrets Manager is the preferred choice over SSM Parameter Store. In production, it is typically recommended to use Secrets Manager whenever possible. However, SSM Parameter Store was chosen for two reasons: cost and simplicity. For our purposes, SSM Parameter Store is free, so retaining the secrets, even after destroying the rest of the infrastructure should incur no additional cost. Addtionally, for this example, only simple and short key/value pairs are needed to configure our environment. 

### Resource Management in Terraform vs Helm

While Helm is a common management tool for kubernetes resources, it can sometimes be more cumbersome and difficult to use than declaring and managing resources directly through Terraform. Although many external services (i.e. the monitoring stack and external-secrets operator) are installed via Helm charts maintained by others, I have opted to mostly use the [kubernetes manifest](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest.html) resource for additional configuration beyond the installation of larger operators and system components. This allows me to more easily visualize and manage dependencies and ordering between Terraform resources, and provides a much simpler way to inject specific configuration values into my k8s manifests.