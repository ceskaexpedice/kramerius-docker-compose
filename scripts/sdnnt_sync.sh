#! /bin/sh

# Configuration   
# Fill in all the placeholders marked with TODO

kramUrl="localhost:8088"

curl -X POST $kramUrl/search/api/admin/v7.0/processes \
     -H "Content-Type: application/json" \
     -H "X-Forwarded-For: TODO" \
     -d '{"defid":"sdnnt-sync","params":{}}'



