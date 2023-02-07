#!/bin/bash

set -euo pipefail
set -x

# Caution: This script can further be enhanced. The aim was to use script for
# quick local testing purpose.

#Obvisously this bash can further be improved.

current_dir=$PWD

usage="(version1) run => provisioning_script.sh apply|delete."

declare -r command=${1:?}

function check_aws_profile() {
	# To detect aws profile to use.
	if [ -z "$(aws sts get-caller-identity)" ]; then echo "ERROR: export AWS_PROFILE"; else echo "aws aws profile found proceeding to artefact_build_upload"; fi
}

function artefact_build_upload() {
	# In directory  nginx-golang-mysql, Dockerizes the application and uploads in AWS ECR through aws cli
	if [ -z "$(aws ecr describe-repositories | jq '.repositories[].repositoryName' | grep -o "hasura-application")" ]; then
		repositoryUri=$(aws ecr create-repository --repository-name hasura-application --region ap-south-1 | jq '.repository.repositoryUri' | tr -d '"')
	fi

	cd $current_dir/env-echo/
	docker build -t $(aws ecr describe-repositories | jq '.repositories[].repositoryUri' | grep hasura-application | sed 's!\"!!g'):latest -f Dockerfile .
	aws ecr get-login-password | docker login --username AWS --password-stdin  $(aws ecr describe-repositories | jq '.repositories[].repositoryUri' | grep hasura-application | sed 's!\"!!g' | awk -F "." '{print $1}').dkr.ecr.ap-south-1.amazonaws.com
	docker push $(aws ecr describe-repositories | jq '.repositories[].repositoryUri' | grep hasura-application | sed 's!\"!!g')
	echo "INFO: uploaded artefact"

}


function backend_s3_tf() {
	# In directory  tfstate_setup, creates S3 and dynamodb to store terraform statefiles and takes care of state locking.
  if [ -z "$(aws s3api list-buckets | jq '.Buckets[].Name' | grep "hasura-assignment-provision")" ] && [ "$(aws dynamodb describe-table --table-name tfstate &> /dev/null; echo $?)" -ne 0 ]; then
	#if [ -z "$(aws s3api list-buckets | jq '.Buckets[].Name' | grep -o "hasura-assignment-provision")"  "$(aws dynamodb describe-table --table-name tfstate)" ]; then
		cd $current_dir/tfstate_setup/
		terraform init
		terraform apply -auto-approve
		echo "INFO: backend_created"
	fi

	echo "INFO: backend_exsist"

}

function all_layers() {
	# In directory  tfstate_setup,  provisions complete stack in layers.
	cd $current_dir/provision/infra
	echo yes | make apply

	cd $current_dir/provision/resources
	make kubeconfig
	echo yes | make apply

	cd $current_dir/provision/services_k8s
	make kubeconfig
	echo yes | make apply

	#URL=$(kubectl get svc -n default -o json | jq '.items[].status.loadBalancer.ingress[0].hostname' | head -n 1)

}

function delete_all_provisioned() {
#	# all_layers and backend_s3_tf and ecr too

	cd $current_dir/provision/services_k8s
	make kubeconfig
	echo yes | make destroy
	make clean

	cd $current_dir/provision/resources
	make kubeconfig
	echo yes | make destroy
	make clean

	cd $current_dir/provision/infra
	echo yes | make destroy
	make clean

	cd $current_dir/tfstate_setup/
	aws s3api delete-objects --bucket hasura-assignment-provision --delete "$(aws s3api list-object-versions --bucket "hasura-assignment-provision" --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" > /dev/null
	terraform destroy -auto-approve

}


case $command in
    "apply") check_aws_profile
    				 artefact_build_upload
    				 backend_s3_tf
    				 all_layers
           ;;
#    "plan") check_aws_profile
#           ;;
    "delete") delete_all_provisioned
esac
