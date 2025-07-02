#!/bin/bash
export CDK_HOSTNAME=$(<../hostname.txt)
echo "Testing user call: Connecting to https://$CDK_HOSTNAME/search/api/cdk/v7.0/forward/user"
curl --verbose --cert ../client/ceskadigitalniknihovna.cz.crt --key ../client/ceskadigitalniknihovna.cz.key --cacert ../certs/$CDK_HOSTNAME.crt   https://$CDK_HOSTNAME/search/api/cdk/v7.0/forward/user
