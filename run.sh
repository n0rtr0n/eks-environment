#!/bin/bash
set -e

command=""

# default options
opt_auto_approve=0

usage() {
 echo "Helper script for automatically spinning up and tearing down Terraform infrastructure in this repository"
 echo "Usage: $0 up|down [options]"
 echo "Options:"
 echo " -a, --auto-aprove  Automatically approve Terraform applies"
 echo " -h, --help         Display this help message"
 exit 1
}

while getopts ":ah" opt; do
  case $opt in
    a) opt_auto_approve=1
      ;;
    h)
      usage
      ;;
    \?)
      usage
    ;;
  esac
done

shift $((OPTIND -1))

while [ "$1" != "" ]; do
  case $1 in 
    --auto-approve)
      opt_auto_approve=1
      shift
      ;;
    --help)
      usage
      shift
      exit 0
      ;;
    up|down)
      command=$1
      shift
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

# we will add these resources in reverse order to be torn down
# states that need to have extra steps should for teardown should include a pre_teardown.sh
# this will automatically run before the terraform destroy is applied
down_states=()
down_states+=("$live_base_dir/eks-config")
down_states+=("$live_base_dir/monitoring")
down_states+=("$live_base_dir/eks-secrets/3-secrets")
down_states+=("$live_base_dir/eks-secrets/2-clustersecretstore")
down_states+=("$live_base_dir/eks-secrets/1-external-secrets")
down_states+=("$live_base_dir/ssm-secrets")
down_states+=("$live_base_dir/eks-cluster")
down_states+=("$live_base_dir/vpc")

# Note: this particular state may need to be deleted manually for now since it requires ECR image deletion
#down_states+=("$global_base_dir")

up() {
  for dir in "${up_states[@]}"; do
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

down() {
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

case $command in
  up)
    up
    ;;
  down)
    down
    ;;
  *)
    usage
    ;;
esac

exit 0