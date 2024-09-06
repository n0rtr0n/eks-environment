#!/bin/bash
set -e

# default options
opt_auto_approve=0
opt_destroy_secrets=0
opt_destroy_global=0

usage() {
 echo "Helper script for automatically spinning up and tearing down Terraform infrastructure in this repository"
 echo "Usage: $0 init|up|down [options]"
 echo "Options:"
 echo " -a, --auto-aprove      Automatically approve Terraform applies"
 echo " -s, --destroy-secrets  Destroy SSM secrets (otherwise they are preserved)"
 echo " -s, --destroy-global   Tear down global state (ECR container registry)"
 echo " -h, --help             Display this help message"
 exit 1
}

# Parse positional arguments (command)
if [ $# -eq 0 ]; then
  usage
fi

command="$1"
shift

shift $((OPTIND -1))

while [ "$1" != "" ]; do
  case $1 in 
    -a|--auto-approve)
      opt_auto_approve=1
      shift
      ;;
    -s|--destroy-secrets)
      opt_destroy_secrets=1
      shift
      ;;
    -g|--destroy-global)
      opt_destroy_global=1
      shift
      ;;
    -h|--help)
      usage
      shift
      exit 0
      ;;
    *)
      usage
      exit 0
      ;;
  esac
done

auto_approve=""
if [ "$opt_auto_approve" -eq 1 ]; then
  auto_approve="--auto-approve"
fi

if [ -z "$command" ]; then
  usage
  exit 1
fi

# prompt to create secrets

# option to preserve:
# * SSM secrets
# * global resources

base_dir=${PWD}
environment="dev"
global_base_dir="$base_dir/live/global"
live_base_dir="$base_dir/live/$environment"

up() {
  # the order matters here for both spinning up and teardown down the infra
  up_states=()
  up_states+=("$global_base_dir")
  up_states+=("$live_base_dir/vpc")
  up_states+=("$live_base_dir/eks-cluster")
  up_states+=("$live_base_dir/ssm-secrets")
  up_states+=("$live_base_dir/eks-secrets/1-external-secrets")
  up_states+=("$live_base_dir/eks-secrets/2-clustersecretstore")
  up_states+=("$live_base_dir/eks-secrets/3-secrets")
  up_states+=("$live_base_dir/monitoring")
  up_states+=("$live_base_dir/eks-config")
  up_states+=("$live_base_dir/tailscale/subnet-router")

  for dir in "${up_states[@]}"; do
    cd $dir
    options=""
    if [ -f "$dir/secrets.tfvars" ]; then
      options="--var-file secrets.tfvars"
    fi
    bash -c "terraform init"
    cmd="terraform apply $auto_approve $options"
    echo "Running \`$cmd\`"
    bash -c "$cmd"
  done 
}

down() {
  # we will add these resources in reverse order to be torn down
  # states that need to have extra steps should for teardown should include a pre_teardown.sh
  # this will automatically run before the terraform destroy is applied
  down_states=()
  down_states+=("$live_base_dir/tailscale/subnet-router")
  down_states+=("$live_base_dir/eks-config")
  down_states+=("$live_base_dir/monitoring")
  down_states+=("$live_base_dir/eks-secrets/3-secrets")
  down_states+=("$live_base_dir/eks-secrets/2-clustersecretstore")
  down_states+=("$live_base_dir/eks-secrets/1-external-secrets")
  if [ "$opt_destroy_secrets" -eq 1 ]; then
    down_states+=("$live_base_dir/ssm-secrets")
  fi 
  down_states+=("$live_base_dir/eks-cluster")
  down_states+=("$live_base_dir/vpc")
  if [ "$opt_destroy_global" -eq 1 ]; then
    down_states+=("$global_base_dir")
  fi 

  kube_cluster_region="us-west-2"
  kube_cluster_name="testing-dev"
  # kubectl used for managing additional resources that Terraform may not be able to interact with
  # namely in pre_teardown.sh scripts associated with each state
  # aws credentials and/or profile should be specified with environment variables
  aws eks update-kubeconfig --region $kube_cluster_region --name $kube_cluster_name 

  for dir in "${down_states[@]}"; do
    cd $dir
    options=""
    if [ -f "$dir/secrets.tfvars" ]; then
      options="--var-file secrets.tfvars"
    fi
    if [ -f "$dir/pre_teardown.sh" ]; then
      bash "$dir/pre_teardown.sh"
    fi
    cmd="terraform destroy $auto_approve $options"
    echo "Running \`$cmd\`"
    bash -c "$cmd"
  done 
}

init() {
  init_states=()
  init_states+=("$global_base_dir")
  init_states+=("$live_base_dir/ssm-secrets")
  for dir in "${init_states[@]}"; do
    cd $dir
    options=""
    if [ -f "$dir/secrets.tfvars" ]; then
      options="--var-file secrets.tfvars"
    fi
    cmd="terraform apply $auto_approve $options"
    echo "Running \`$cmd\`"
    bash -c "$cmd"
  done 
}

case $command in
  up)
    up
    ;;
  down)
    down
    ;;
  init)
    init
    ;;
  *)
    usage
    ;;
esac

exit 0