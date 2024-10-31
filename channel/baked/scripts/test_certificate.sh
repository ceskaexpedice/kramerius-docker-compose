#/bin/bash
export CDK_HOSTNAME=$(<../hostname.txt)
echo "Testing client certificate: Connecting to https://cdk-auth.$CDK_HOSTNAME/"
curl --verbose --cert ../client/ceskadigitalniknihovna.cz.crt --key ../client/ceskadigitalniknihovna.cz.key --cacert ../certs/cdk-auth.$CDK_HOSTNAME.crt    https://cdk-auth.$CDK_HOSTNAME/
