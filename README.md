# Docker compose 
Docker compose balíček pro spuštění všech služeb krameria. 

Spouštěné služby:
 - Eduid keycloak
 - IIP server
 - Solr verze 9.X
 - Jádro krameria
 - Pomocné databáze postgres (pro jádro a pro keycloak)

## Nutné instalační kroky
 1. Zkontrolovat či nahradit aktuální verzi jádra v `docker compose` https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/docker-compose.yml#L5
 2. Pozměnit doménu pro keycloak v docker compose [zde](https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/docker-compose.yml#L144-L145)
 3. Synchornizovat [jádra](https://github.com/ceskaexpedice/kramerius-docker-compose/tree/main/mnt/containers/solr/data) s [aktuálním stavem](https://github.com/ceskaexpedice/kramerius/tree/master/installation/solr-9.x) a dát jim plná práva pro zápis
 4. Upravit konfiguraci dle aktuálního stavu v souboru `configuration.properties`:
     - https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/configuration.properties#L22 - Adresa klientské aplikace
     - https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/configuration.properties#L16 - Cesta k api serveru
 5. Upravit konfiguraci dle aktuálního stavu v souboru `migration.properties`:
     - https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/migration.properties#L4 - Domena imageserveru
     - https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/migration.properties#L5 - Domena imageserveru
     - https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/migration.properties#L15 - Domena audioserveru
 6. Do adresáře pro [keycloak theme](https://github.com/ceskaexpedice/kramerius-docker-compose/tree/main/mnt/containers/eduid/providers) nahrát téma z [tohoto projektu](https://github.com/ceskaexpedice/keycloak-kramerius-theme/releases/tag/7.0.32) a postupovat dle [tohoto návodu](https://github.com/ceskaexpedice/keycloak-kramerius-theme?tab=readme-ov-file#keycloak-theme-kramerius).
 7. Pozměnit [keycloak.json](https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/mnt/import/.kramerius4/keycloak.json#L3). 


## Chráněný kanál
Docker compose obsahuje image, který realizuje chráněný kanál pro zapojení do ČDK.  Při spouštění vytvoří serverové i klientské certifikáty, zip soubor, pro poslání certifikátů adminstrátorům ČDK a konfiguraci pro předsazený apache.

### Spuštění image pro chráněný kanál

1. Je nutno nastavit envinroment proměnnou, která definuje pro jaký server jsou certifikáty generovány. Viz  [CDK_HOSTNAME](https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/docker-compose.yml#L177) Poznámka: Skripty automaticky přidáví prefix **cdk-auth.**.  Tedy, pokud je v proměnné hodnota **kramerius.instituce.cz**, pak certifikáty budou vygenerovány pro server **cdk-auth.kramerius.instituce.cz**.

2. Je nutno nastavit cesty:
 - Pro certifikáty viz https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/docker-compose.yml#L173
    Vygenerované adresáře mají následující strukturu:
      * `ca`   - Adresář obahující certifikáty pro certifikační autoritu
      * `certs` - Adresář obsahující serverovské certifikáty používané chráněným kanálem
      * `certs` - Adresář obsahující klientské certifikáty používané serverm ČDK
      * `scripts` - Skripty pro testování chráněného kanálu
      * `zip`  - Zip pro distribuci - Tento zip se posílá administrátorům ČDK
      * `hostname.txt` - Textový soubor obsahující informace o doméně pro kterou byl kanál generován      
 - Pro konfiguraci viz https://github.com/ceskaexpedice/kramerius-docker-compose/blob/main/docker-compose.yml#L174
      * `httpd.conf`, `mime`, `magic`, `extra/httpd-ssl.conf`  - Konfigurační soubory pro apache, který realizuje chráněný kanál v dockeru. Pokud je chráněný kanál spouštěný v rámci docker compose, není potřeba konfiguraci měnit
      * Adresář `cdk-auth.kramerius.instituce.cz` - Konfigurační souboru pro představený apache server. Je nutno pozměnit `/TODO_PATH/` 

Poznámka: Adresáře `ssl` a `conf` na lokálním stroji je nutno nejdříve vytvořit jako prázdné.

## Generovani logu pro NKP

1. Je potrebe nechat zridit v NKP sftp pristup a dodat verejny klic daneho serveru ze ktereho se budou logy posilat
2. Pridat do `/data/kramerius` adresar `scripts` z kramerius-docker-compose repo
3. spustit command `crontab -e` a doplnit nasledujici radky:
```   
   # NKP Logs
   0 3 * * * /data/kramerius/cronscripts/generateLogs.sh
   
   # SDNNT sync
   0 21 * * 1,3,5 /data/kramerius/cronscripts/sdnnt_sync.sh

   # SDNNT apply
   0 23 * * 1,3,5 /data/kramerius/cronscripts/sdnnt_apply.sh
```

    
