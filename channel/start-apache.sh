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

	
	#Zip file 
	zip -j "$ZIP_DIR/certificates.zip" "$CLIENT_DIR/ceskadigitalniknihovna.cz.crt" "$CLIENT_DIR/ceskadigitalniknihovna.cz.key" "$CA_DIR/kramerius-ca.crt"

fi

# Spuštění Apache
httpd-foreground
