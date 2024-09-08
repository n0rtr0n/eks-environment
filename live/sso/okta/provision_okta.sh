#!/bin/bash

export $(grep -v '^#' .env | xargs)
export OKTA_API_PRIVATE_KEY=`cat ./client_secret_key.pem`

terraform init
terraform apply