#!/bin/bash -e

# Usage:
# 
#   1. set $CIRCLE_API_TOKEN
#   2. run `./trigger-build <account> <project> [<branch>]`
#
#   For https://github.com/iambob/myfirstproject:
#
#       trigger_build iambob myfirstproject
#
#   ... will build master
_account=$1 # github user name or organization name
_project=$2 # repo name
_branch=$3

_circle_token=${CIRCLE_API_TOKEN}



echo "Triggering build of $_project ($_branch)."
trigger_build_url="https://circleci.com/api/v1.1/project/github/${_account}/${_project}/tree/${_branch}"

curl -u ${CIRCLE_API_TOKEN}: \
	-d build_parameters[CIRCLE_JOB]=build \
	"${trigger_build_url}"
