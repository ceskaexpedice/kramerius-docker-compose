#! /bin/sh

# Configuration   
# Fill in all the placeholders marked with TODO

kramUrl="localhost:8088"

curl -X GET $kramUrl/search/api/admin/v7.0/sdnnt/sync/batches \
     -H "Content-Type: application/json" \
     -H "X-Forwarded-For: TODO" 



