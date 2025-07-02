#!/bin/bash
export VERSION=$(<version.txt)
docker build -t ceskaexpedice/kramerius-secured-channel:$VERSION .


