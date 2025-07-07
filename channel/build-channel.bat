@echo off 

set /p VERSION=<version.txt
echo "Building image ceskaexpedice/kramerius-secured-channel:%VERSION%"
docker build -t ceskaexpedice/kramerius-secured-channel:%VERSION% .

rem docker build -t ceskaexpedice/kramerius-secured-channel:1.0.4 .


