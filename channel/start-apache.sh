#!/bin/bash

# Preparing directory structure
mkdir "/usr/local/etc/ssl/client"
mkdir "/usr/local/etc/ssl/certs"
mkdir "/usr/local/etc/ssl/ca"
mkdir "/usr/local/etc/ssl/zip"
mkdir "/usr/local/etc/ssl/scripts"

chown -R 0.0 /usr/local/etc/ssl
chown -R 0.0 /usr/local/etc/ssl/client
chmod 750 /usr/local/etc/ssl/client

if [ -z "$CDK_HOSTNAME" ]; then
    echo "No CDK_HOSTNAME"
    exit 1
fi

# Directory structure
export CERT_DIR="/usr/local/etc/ssl/certs"
export CLIENT_DIR="/usr/local/etc/ssl/client"
export CA_DIR="/usr/local/etc/ssl/ca"
export ZIP_DIR="/usr/local/etc/ssl/zip"

export HTTP_CONF_FILE="/usr/local/apache2/conf/httpd.conf"
export HTTPS_CONF_FILE="/usr/local/apache2/conf/extra/httpd-ssl.conf"

export COUNTRY=""
export STATE=""
export ORGANIZATION=""
export COMMON_NAME="cdk-auth.$CDK_HOSTNAME"
export ALT_NAMES="DNS:cdk-auth.$CDK_HOSTNAME"

cp -r /usr/local/apache2/_init_/conf /usr/local/apache2/
cp -r /usr/local/apache2/_init_/scripts /usr/local/etc/ssl/


# Generování certifikátu, pokud neexistuje
#if [ ! -f "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.crt" ] && [ ! -f "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.key" ]; then
if [ ! -f "/usr/local/etc/ssl/hostname.txt" ] || [ "$(cat /usr/local/etc/ssl/hostname.txt)" != "$CDK_HOSTNAME" ]; then

    echo "$CDK_HOSTNAME" > "/usr/local/etc/ssl/hostname.txt"
	
	printf "Generating certificates .."
	
    # Generování hesla pro CA
    #CA_PASSWORD=$(pwgen -1 16)
	export CA_PASSWORD=$(openssl rand -base64 16)

    echo "$CA_PASSWORD" > "$CA_DIR/ca_password.txt"
    
	# mkdir for  CA
    mkdir -p "$CA_DIR"

    
	# CA 
	openssl genrsa -des3 -out "$CA_DIR/kramerius-ca.key" -passout env:CA_PASSWORD 2048
	openssl req -x509 -new -nodes -key "$CA_DIR/kramerius-ca.key" -sha256 -days 7300 -out "$CA_DIR/kramerius-ca.crt" -passin env:CA_PASSWORD -subj "/C=$COUNTRY/ST=$STATE/O=$ORGANIZATION/CN=$COMMON_NAME" -addext "subjectAltName = $ALT_NAMES"

	# cdk-auth
	printf "authorityKeyIdentifier=keyid,issuer\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment\nsubjectAltName=@alt_names\n\n[alt_names]\nDNS.1=cdk-auth.${CDK_HOSTNAME}\n" > "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.ext"
	openssl genrsa -out "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.key" 2048
	openssl req -new -nodes -key "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.key" -out "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.csr" -subj "/C=$COUNTRY/ST=$STATE/O=$ORGANIZATION/CN=$COMMON_NAME" -addext "subjectAltName = DNS:cdk-auth.$CDK_HOSTNAME"
	openssl x509 -req -in "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.csr" -CA "$CA_DIR/kramerius-ca.crt" -CAkey "$CA_DIR/kramerius-ca.key" -CAcreateserial -out "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.crt" -days 5475 -sha256 -extfile "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.ext" -passin env:CA_PASSWORD
	

	
	#Client certificate
	printf "subjectAltName = @alt_names\n\n[alt_names]\nDNS.1 = czechdigitallibrary.cz\n" > "$CLIENT_DIR/ceskadigitalniknihovna.cz.ext"
	openssl genrsa -out "$CLIENT_DIR/ceskadigitalniknihovna.cz.key" 2048
	openssl req -new -nodes -sha256 -key "$CLIENT_DIR/ceskadigitalniknihovna.cz.key" -out "$CLIENT_DIR/ceskadigitalniknihovna.cz.csr" -subj "/C=CZ/ST=Czech republic/CN=czechdigitallibrary.cz"  -addext "subjectAltName = DNS:czechdigitallibrary.cz"
	openssl x509 -req -in "$CLIENT_DIR/ceskadigitalniknihovna.cz.csr"  -CA "$CA_DIR/kramerius-ca.crt" -CAkey "$CA_DIR/kramerius-ca.key" -CAcreateserial -out "$CLIENT_DIR/ceskadigitalniknihovna.cz.crt" -days 5475 -sha256 -extfile "$CLIENT_DIR/ceskadigitalniknihovna.cz.ext" -passin env:CA_PASSWORD
	cat "$CLIENT_DIR/ceskadigitalniknihovna.cz.crt" > "$CLIENT_DIR/cdk-proxy.crt"
	cat "$CLIENT_DIR/ceskadigitalniknihovna.cz.key" >> "$CLIENT_DIR/cdk-proxy.crt"
	

	
	#Zip file 
	zip -j "$ZIP_DIR/certificates.zip" "$CLIENT_DIR/ceskadigitalniknihovna.cz.crt" "$CLIENT_DIR/ceskadigitalniknihovna.cz.key" "$CA_DIR/kramerius-ca.crt" "$CERT_DIR/cdk-auth.$CDK_HOSTNAME.crt"

	#Mkdir 
    mkdir "/usr/local/apache2/conf/cdk-auth.$CDK_HOSTNAME"
	
	#Configuration
	printf "<VirtualHost *:80>\n\
    ServerAdmin admin@cdk-auth.$CDK_HOSTNAME\n\
    ServerName cdk-auth.$CDK_HOSTNAME\n\
    ServerAlias cdk-auth.$CDK_HOSTNAME\n\
    DocumentRoot /var/www/cdk-auth.$CDK_HOSTNAME\n\
    ErrorLog \${APACHE_LOG_DIR}/error.log\n\
    CustomLog \${APACHE_LOG_DIR}/access.log combined\n\
	\n\
    RewriteEngine on\n\
    RewriteCond %%{SERVER_NAME} =cdk-auth.$CDK_HOSTNAME\n\
    RewriteRule ^ https://%%{SERVER_NAME}%%{REQUEST_URI} [END,NE,R=permanent]\n\
	</VirtualHost>\n" > "/usr/local/apache2/conf/cdk-auth.$CDK_HOSTNAME/cdk-auth.$CDK_HOSTNAME.conf"		
		

	printf "<IfModule mod_ssl.c>\n\
	<VirtualHost *:443>\n\
    ServerAdmin admin@cdk-auth.$CDK_HOSTNAME\n\
    ServerName cdk-auth.$CDK_HOSTNAME\n\
    ServerAlias cdk-auth.$CDK_HOSTNAME\n\
    DocumentRoot /var/www/cdk-auth.$CDK_HOSTNAME\n\
    ErrorLog \${APACHE_LOG_DIR}/error.log\n\
    CustomLog \${APACHE_LOG_DIR}/access.log combined\n\
	\n\
    <LocationMatch \"^/search/(.*)$\">\n\
      SSLOptions +StdEnvVars\n\
	\n\
      <IfModule mod_proxy.c>\n\
        ProxyPreserveHost On\n\
		\n\
        ProxyPass \"https://127.0.0.1:8443/search/\$1\" retry=5\n\
        ProxyPassReverse \"https://127.0.0.18443/search/\$1\"\n\
		\n\
        <RequireAll>\n\
          <RequireAny>\n\
            Require expr %%{SSL_CLIENT_S_DN_CN} == \"ceskadigitalniknihovna.cz\"\n\
            Require expr %%{SSL_CLIENT_S_DN_CN} == \"czechdigitallibrary.cz\"\n\
          </RequireAny>\n\
        </RequireAll>\n\
      </IfModule>\n\
    </LocationMatch>\n\
	\n\
    <Directory /var/www/k7.inovatika.dev>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
	\n\
    SSLEngine On\n\
    SSLUseStapling Off\n\
    SSLVerifyClient require\n\
    SSLVerifyDepth 10\n\
	\n\
    SSLCertificateFile /TODO_PATH/ssl/certs/cdk-auth.$CDK_HOSTNAME.crt\n\
    SSLCertificateKeyFile /TODO_PATH/ssl/certs/cdk-auth.$CDK_HOSTNAME.key\n\
    SSLCACertificateFile /TODO_PATH/ssl/ca/kramerius-ca.crt\n\
    SSLProxyEngine on\n\
	\n\
    SSLProxyMachineCertificateFile /TODO_PATH/ssl/client/cdk-proxy.crt\n\
	\n\
	</VirtualHost>\n\
	</IfModule>\n" >  "/usr/local/apache2/conf/cdk-auth.$CDK_HOSTNAME/cdk-auth.${CDK_HOSTNAME}-ssl.conf"	
		
		
fi

# Spuštění Apache
httpd-foreground
