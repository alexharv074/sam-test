#!/usr/bin/env bash

if [ "$1" == "-h" ] ; then
  echo "Usage: $0 [-h] [REST_API_NAME]"
  exit 1
fi

if [ ! -z "$1" ] ; then
  rest_api_name=$1
fi

echo "APIs:"
if [ -z "$rest_api_name" ] ; then
  aws apigateway get-rest-apis > rest_apis.json
  rest_api_ids=$(jq -r '.items[].id' rest_apis.json \
    2> /dev/null || true) # true handles no APIs.
else
  aws apigateway get-rest-apis \
    --query 'items[?name==`'$rest_api_name'`]' > rest_apis.json
  rest_api_ids=$(jq -r '.[].id' rest_apis.json \
    2> /dev/null || true)
fi
jq . rest_apis.json

for rest_api_id in $rest_api_ids ; do

  echo "API resources:"
  aws apigateway get-resources \
    --rest-api-id $rest_api_id > resources.json
  jq . resources.json

  resource_ids=$(jq -r '.items[].id' resources.json)

  for resource_id in $resource_ids ; do

    methods=$(jq -r --arg id $resource_id \
      '.items[] | select(.id == $id) | .resourceMethods | keys | @tsv' \
        resources.json 2> /dev/null || true)

    for method in $methods ; do

      echo "API method $method:"
      aws apigateway get-method --http-method $method \
        --resource-id $resource_id --rest-api-id $rest_api_id \
          > methods-$resource_id-$method.json
      jq . methods-$resource_id-$method.json

    done
  done

  echo "API models:"
  aws apigateway get-models \
    --rest-api-id $rest_api_id > models.json
  jq . models.json
done

rm -f rest_apis.json resources.json methods*json models.json
