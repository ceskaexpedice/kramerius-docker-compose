@echo off 

docker run ^
  -e "CDK_HOSTNAME=happy.int" ^
  -p 443:443 ^
  -v %cd%\ssl:/usr/local/etc/ssl/ ^
  -v %cd%\conf:/usr/local/apache2/conf/ ^
  -v %cd%\docs:/usr/local/apache2/docs/ ^
  ceskaexpedice/kramerius-secured-channel:1.0.2



