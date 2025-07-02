#!/bin/bash
export CDK_HOSTNAME=$(<../hostname.txt)
echo "Testing client certificate: Connecting to https://$CDK_HOSTNAME/"
curl --verbose --cert ../client/ceskadigitalniknihovna.cz.crt --key ../client/ceskadigitalniknihovna.cz.key --cacert ../certs/$CDK_HOSTNAME.crt    https://$CDK_HOSTNAME/
