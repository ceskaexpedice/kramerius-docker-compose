#!/bin/sh

# Configuration
# Fill in all placeholders marked with TODO

kramUrl="http://localhost:8088"
clientId="TODO"
clientSecret="TODO"
forwardedFor="TODO"

tokenResponse=$(
  curl -s -X GET \
    "$kramUrl/search/api/exts/v7.0/tokens/$clientId?secrets=$clientSecret"
)

accessToken=$(printf '%s' "$tokenResponse" | jq -r '.access_token')

if [ -z "$accessToken" ] || [ "$accessToken" = "null" ]; then
  echo "Failed to obtain access token"
  echo "$tokenResponse"
  exit 1
fi

curl -X GET "$kramUrl/search/api/admin/v7.0/sdnnt/sync/batches" \
  -H "Content-Type: application/json" \
  -H "X-Forwarded-For: $forwardedFor" \
  -H "Authorization: Bearer $accessToken"