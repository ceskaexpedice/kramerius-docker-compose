#/bin/bash
export CDK_HOSTNAME=$(<../hostname.txt)
echo "Testing info call: Connecting to https://cdk-auth.$CDK_HOSTNAME/search/api/client/v7.0/info"
curl --verbose --cert ../client/ceskadigitalniknihovna.cz.crt --key ../client/ceskadigitalniknihovna.cz.key --cacert ../ca/kramerius-ca.crt   https://cdk-auth.$CDK_HOSTNAME/search/api/client/v7.0/info
