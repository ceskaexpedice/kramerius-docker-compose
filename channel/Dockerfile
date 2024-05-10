FROM httpd:2.4


RUN apt-get update && apt-get install -y \
    openssl \
    zip \
    curl

COPY start-apache.sh /usr/local/bin/start-apache.sh

COPY baked/ /usr/local/apache2/_init_

RUN chmod +x /usr/local/bin/start-apache.sh

CMD ["start-apache.sh"]
