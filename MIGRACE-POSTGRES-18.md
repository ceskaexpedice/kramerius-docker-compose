# Migrace PostgreSQL na verzi 18

Databáze v docker-compose běží na Postgresu 18. Verze se nastavují v `.env` dvěma proměnnými, takže databáze Krameria a keycloaku lze upgradovat nezávisle:

| Služba | Účel | Uživatel / DB | Původní verze | Proměnná v `.env` | Nový adresář s daty |
|---|---|---|---|---|---|
| `krameriusPostgres` | jádro | `fedoraAdmin` / `kramerius` | 10.1 | `KRAMERIUS_POSTGRES_VERSION` | `mnt/containers/krameriuspostgres18` |
| `processPostgres` | procesy | `process` / `process` | 10.1 | `KRAMERIUS_POSTGRES_VERSION` | `mnt/containers/processpostgres18` |
| `keycloakPostgres_eduid` | keycloak | `keycloak` / `keycloak` | 14.10 | `KEYCLOAK_POSTGRES_VERSION` | `mnt/containers/keycloakpostgres_eduid18` |

## Koho se to týká

- **Nová instalace:** nic dalšího se dělat nemusí. Nové adresáře se při prvním `docker compose up -d` vytvoří a databáze se inicializují samy.
- **Stávající instalace:** postupujte podle tohoto návodu. Kroky 1–3 udělejte **ještě se starým** `docker-compose.yml`, tedy dřív, než stáhnete novou verzi.

## Proč nestačí jen změnit verzi image

- Nová major verze Postgresu neotevře data starší verze a skončí chybou `database files are incompatible with server`. Proto je nutný dump a restore.
- Image `postgres` od verze 18 ukládá data do `/var/lib/postgresql/18/docker` a volume očekává na `/var/lib/postgresql`. Když je něco připojeno na `/var/lib/postgresql/data`, kontejner odmítne nastartovat. Proto se v `docker-compose.yml` změnila cesta připojení (bez `/data`).
- Data jsou v nových adresářích (`...18`). Původní adresáře zůstanou nedotčené a slouží jako záloha a pro návrat zpět.

## Před začátkem

- Počítejte s odstávkou Krameria po dobu migrace.
- Volné místo na disku: zhruba dvojnásobek velikosti stávajících adresářů s databázemi.
- Všechny příkazy spouštějte v adresáři s `docker-compose.yml`, například `/data/kramerius`. Na serveru může být potřeba `sudo`.
- Příkazy počítají s výchozími uživateli a databázemi z `docker-compose.yml`, které uvádí tabulka nahoře (`-U fedoraAdmin -d kramerius` atd.). Pokud jste je u své instalace změnili (proměnné `POSTGRES_USER` a `POSTGRES_DB` u dané služby), napište do `-U` a `-d` svoje hodnoty. Hesla zadávat nemusíte, protože příkazy běží uvnitř kontejneru databáze.
- **Windows a Git Bash:** nejdřív spusťte `export MSYS_NO_PATHCONV=1`. Jinak Git Bash přepíše cesty `/tmp/...` na cesty Windows a `pg_dump` uvnitř kontejneru selže.
- **Windows a PowerShell:** příkazy `docker compose ...` fungují beze změny. Jinak zapište jen tyto příkazy: místo `mkdir -p` použijte `mkdir`, místo `cp -a` použijte `Copy-Item -Recurse` a místo `ls -l` použijte `dir`. Výstup `pg_dump` nikdy nepřesměrovávejte přes `>`, protože PowerShell binární dump poškodí. Proto návod zapisuje dump uvnitř kontejneru a kopíruje ho přes `docker compose cp`.

## 1. Zastavit aplikace

```bash
docker compose stop kramerius curatorWorker publicWorker processManager keycloak_eduid
```

## 2. Dump všech tří databází (stále běží staré verze)

**Používejte `pg_dump` pro každou databázi zvlášť, ne `pg_dumpall`.** `pg_dumpall` přenese i role s heslem uloženým jako md5 hash. Postgres 18 v image ověřuje přes scram-sha-256, takže by se aplikace po obnově nepřihlásily.

```bash
mkdir -p pg18-migrace
docker compose exec krameriusPostgres pg_dump -U fedoraAdmin -Fc -f /tmp/kramerius.dump kramerius
docker compose cp krameriusPostgres:/tmp/kramerius.dump ./pg18-migrace/kramerius.dump
docker compose exec processPostgres pg_dump -U process -Fc -f /tmp/process.dump process
docker compose cp processPostgres:/tmp/process.dump ./pg18-migrace/process.dump
docker compose exec keycloakPostgres_eduid pg_dump -U keycloak -Fc -f /tmp/keycloak.dump keycloak
docker compose cp keycloakPostgres_eduid:/tmp/keycloak.dump ./pg18-migrace/keycloak.dump
ls -l pg18-migrace
```

Všechny tři soubory musí mít nenulovou velikost.

Pro pozdější kontrolu si poznamenejte počet tabulek v každé databázi:

```bash
docker compose exec krameriusPostgres psql -U fedoraAdmin -d kramerius -tc "select count(*) from pg_tables where schemaname='public'"
docker compose exec processPostgres psql -U process -d process -tc "select count(*) from pg_tables where schemaname='public'"
docker compose exec keycloakPostgres_eduid psql -U keycloak -d keycloak -tc "select count(*) from pg_tables where schemaname='public'"
```

## 3. Zastavit staré databáze a zazálohovat jejich adresáře (doporučeno)

```bash
docker compose stop krameriusPostgres processPostgres keycloakPostgres_eduid kramerius_pgbackups keycloak_pgbackups
cp -a mnt/containers/krameriuspostgres mnt/containers/krameriuspostgres_pg10_backup
cp -a mnt/containers/processpostgres mnt/containers/processpostgres_pg10_backup
cp -a mnt/containers/keycloakpostgres_eduid mnt/containers/keycloakpostgres_eduid_pg14_backup
```

## 4. Nová verze `docker-compose.yml` a `.env`

Stáhněte novou verzi (`git pull`). Pokud máte vlastní úpravy, proveďte změny ručně.

`.env`:

```
KRAMERIUS_POSTGRES_VERSION=18.6
KEYCLOAK_POSTGRES_VERSION=18.6
```

`docker-compose.yml`, u všech tří databází:

```yaml
  krameriusPostgres:
    image: "postgres:${KRAMERIUS_POSTGRES_VERSION}"
    volumes:
      - ./mnt/containers/krameriuspostgres18:/var/lib/postgresql

  processPostgres:
    image: "postgres:${KRAMERIUS_POSTGRES_VERSION}"
    volumes:
      - ./mnt/containers/processpostgres18:/var/lib/postgresql

  keycloakPostgres_eduid:
    image: "postgres:${KEYCLOAK_POSTGRES_VERSION}"
    volumes:
      - ./mnt/containers/keycloakpostgres_eduid18:/var/lib/postgresql
```

U zálohovacích kontejnerů `kramerius_pgbackups` a `keycloak_pgbackups`:

```yaml
    image: prodrigestivill/postgres-backup-local:18
```

Proč je to potřeba:

- Zálohovací kontejner zálohuje databázi vlastním programem `pg_dump`, který je součástí jeho image. `pg_dump` umí zálohovat jen server stejné nebo starší verze.
- Image bez verze (tag `latest`) Docker stáhne jen při prvním spuštění. Pak už používá tuto lokální kopii a novější sám nestahuje. Na serveru instalovaném například v roce 2023 je proto `latest` image z roku 2023 se starším `pg_dump`.
- Takový `pg_dump` na serveru verze 18 skončí chybou `server version mismatch`. Kontejner přitom dál běží, takže si nikdo nevšimne, že noční zálohy nevznikají.
- S tagem `:18` Docker zjistí, že takový image lokálně nemá, a stáhne verzi s `pg_dump` 18.

## 5. Spustit jen nové databáze

```bash
docker compose up -d krameriusPostgres processPostgres keycloakPostgres_eduid
docker compose logs -f krameriusPostgres processPostgres keycloakPostgres_eduid
```

Počkejte, až všechny tři vypíšou `database system is ready to accept connections`, a pak ukončete výpis přes Ctrl+C.

**Celý stack zatím nespouštějte.** Jádro a keycloak by si do prázdné databáze založily vlastní tabulky a obnova dat by s nimi kolidovala.

## 6. Obnova dat

```bash
docker compose cp ./pg18-migrace/kramerius.dump krameriusPostgres:/tmp/kramerius.dump
docker compose exec krameriusPostgres pg_restore -U fedoraAdmin -d kramerius /tmp/kramerius.dump
docker compose cp ./pg18-migrace/process.dump processPostgres:/tmp/process.dump
docker compose exec processPostgres pg_restore -U process -d process /tmp/process.dump
docker compose cp ./pg18-migrace/keycloak.dump keycloakPostgres_eduid:/tmp/keycloak.dump
docker compose exec keycloakPostgres_eduid pg_restore -U keycloak -d keycloak /tmp/keycloak.dump
```

Tyto chyby jsou očekávané a neškodné (`pg_restore` pak vypíše `errors ignored on restore: 2`):

- `schema "public" already exists`: nová databáze schéma `public` už má.
- `role "postgres" does not exist`: ve staré databázi patřilo schéma roli `postgres`, která v nové instalaci neexistuje. Schéma zůstane ve vlastnictví vlastníka databáze.

Při jakékoli jiné chybě nepokračujte a zjistěte příčinu.

Spusťte znovu dotazy na počet tabulek z kroku 2. Čísla musí sedět.

## 7. Spustit vše a otestovat

```bash
docker compose up -d
docker compose logs -f kramerius processManager keycloak_eduid
```

Zkontrolujte:

- v logu nejsou `PSQLException`, `SQLException` ani chyby přihlášení (např. `authentication type 10 is not supported`),
- webový klient načte a zobrazí dokumenty,
- přihlášení do admin klienta funguje (jde přes keycloak) a funguje i administrace keycloaku,
- proces spuštěný z admin klienta doběhne.

## 8. Úklid

Po několika dnech bezproblémového provozu můžete smazat:

- původní adresáře `krameriuspostgres`, `processpostgres`, `keycloakpostgres_eduid`,
- zálohy `*_pg10_backup` a `*_pg14_backup`,
- adresář `pg18-migrace`.

## Návrat zpět

1. V `docker-compose.yml` vraťte původní image (`postgres:10.1`, `postgres:14.10`) a původní připojení:

   ```yaml
         - ./mnt/containers/krameriuspostgres:/var/lib/postgresql/data
         - ./mnt/containers/processpostgres:/var/lib/postgresql/data
         - ./mnt/containers/keycloakpostgres_eduid:/var/lib/postgresql/data
   ```

2. Spusťte `docker compose up -d`.

Původní adresáře migrace nezměnila. Data zapsaná po migraci zůstanou jen v adresářích `...18`.

## Poznámky

- **Minor verze** (např. 18.6 → 18.7): stačí změnit `KRAMERIUS_POSTGRES_VERSION` nebo `KEYCLOAK_POSTGRES_VERSION` a spustit `docker compose up -d`. Migrace není potřeba.
- **Major verze** (např. 18 → 19): je potřeba znovu dump a restore podle tohoto návodu, a to jen pro databáze, jejichž proměnnou měníte. Pro databáze Krameria jde o kroky pro `krameriusPostgres` a `processPostgres`, pro keycloak o kroky pro `keycloakPostgres_eduid`. Při změně major verze upravte i tag zálohovacího kontejneru (`prodrigestivill/postgres-backup-local:<major>`).
- **Uživatelé Krameria a keycloaku** (účty, role a skupiny v keycloaku, práva v Krameriu) jsou uložení v tabulkách databáze a dump je přenese, nic dalšího se dělat nemusí.
- **Vlastní přihlašovací účty přímo v Postgresu** (výjimečně, např. účet jen pro čtení pro reporting přes port 15432): dump po databázích je nepřenese. Pokud nějaké máte, vypište je příkazem `pg_dumpall -U <uživatel> --roles-only`, na nové databázi je založte a hesla nastavte znovu přes `ALTER ROLE ... PASSWORD '...'`.
- **Kontrolní součty:** Postgres 18 je u nových databází zapíná ve výchozím stavu. Pro dump a restore to nehraje roli.
- **Otestováno** lokálně 20. 10. 2026: jádro 7.2.x, process-manager 1.5, keycloak_eduid 22.0.11-1.10.
