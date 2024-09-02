#!/bin/bash

namespace="applications-dev"
resource_name="applications-dev"

kubectl delete ing -n $namespace $resource_name