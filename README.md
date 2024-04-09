# Docker compose 
Docker compose balíček pro spuštění všech služeb krameria. 

Spouštěné služby:
 - Eduid keycloak
 - IIP server
 - Solr verze 9.X
 - Jádro krameria
 - Pomocné databáze solr

## Nutné instalační kroky
 1. Zkontrolovat či nahradit aktuální verzi jádra v `docker compose` https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/docker-compose.yml#L5
 2. Synchornizovat [jádra](https://github.com/ceskaexpedice/kramerius-docker-compose/tree/main/solrdata) s [aktuálním stavem](https://github.com/ceskaexpedice/kramerius/tree/master/installation/solr-9.x) 
 3. Upravit konfiguraci dle aktuálního stavu:
     - https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/configuration.properties#L22 - Adresa klientské aplikace
     - https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/configuration.properties#L16 - Cesta k api serveru
 4. Do adresáře pro [keycloak theme](https://github.com/ceskaexpedice/kramerius-docker-compose/tree/main/mnt/containers/eduid/providers) nahrát téma z [tohoto projektu](https://github.com/ceskaexpedice/keycloak-kramerius-theme/releases/tag/7.0.32) a postupovat dle [tohoto návodu](https://github.com/ceskaexpedice/keycloak-kramerius-theme).

