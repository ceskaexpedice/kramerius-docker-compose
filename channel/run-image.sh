#!/bin/bash
export VERSION=$(<version.txt)
docker run -e "CDK_HOSTNAME=kramerius-cdk.uk.tul.cz" -p 443:443 -v $(pwd)/ssl:/usr/local/etc/ssl/ -v $(pwd)/conf:/usr/local/apache2/conf/ -v $(pwd)/docs:/usr/local/apache2/docs/ ceskaexpedice/kramerius-secured-channel:$VERSION



