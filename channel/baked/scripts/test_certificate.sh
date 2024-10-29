#/bin/bash
export CDK_HOSTNAME=$(<../hostname.txt)
echo "Testing client certificate: Connecting to https://cdk-auth.$CDK_HOSTNAME/"
curl --verbose --cert ../client/ceskadigitalniknihovna.cz.crt --key ../client/ceskadigitalniknihovna.cz.key --cacert ../ca/kramerius-ca.crt   https://cdk-auth.$CDK_HOSTNAME/
