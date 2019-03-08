#!/usr/bin/env bash

stack_name='sam-app'
cd $stack_name

set -x

aws cloudformation delete-stack --stack-name $stack_name
aws cloudformation wait stack-delete-complete --stack-name $stack_name
