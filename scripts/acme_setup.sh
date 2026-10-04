#!/usr/bin/env bash
set -euo pipefail

# Certifikaty se vydavaji samostatne pro kazdou domenu, protoze Apache
# konfigurace v tomto projektu ocekava tri konkretni dvojice souboru.
#
# CERT_DIR odpovida adresari, ktery je v docker-compose.yml namapovany
# do kontejneru kramerius_httpd_proxy jako /etc/ssl/kramerius_httpd_proxy.
# Pokud je skript spusteny pod rootem, acme.sh se nainstaluje do /root/.acme.sh.
ACME_EMAIL="kramerius@inovatika.cz"
CERT_DIR="/data/kramerius/mnt/containers/kramerius_httpd_proxy/certs"
ACME_HOME="$HOME/.acme.sh"
ACME_SH="$ACME_HOME/acme.sh"
ACME_SERVER="letsencrypt"
KEY_TYPE="ec-256"
FORCE_RENEW="false"

# Standalone validace potrebuje volny port 80. Pokud proxy kontejner existuje,
# acme.sh ho pred validaci zastavi a po validaci zase spusti. Pokud kontejner
# jeste neexistuje, hooky nic neudelaji a skript pokracuje dal.
PRE_HOOK="docker container inspect kramerius_httpd_proxy >/dev/null 2>&1 && docker stop kramerius_httpd_proxy || true"
POST_HOOK="docker container inspect kramerius_httpd_proxy >/dev/null 2>&1 && docker start kramerius_httpd_proxy || true"

# Po nainstalovani nebo obnoveni certifikatu se proxy restartuje, pokud uz
# existuje. Pri prvnim setupu pred spustenim Dockeru se tento krok preskoci.
RELOAD_CMD="docker container inspect kramerius_httpd_proxy >/dev/null 2>&1 && docker restart kramerius_httpd_proxy || true"

# Domeny, pro ktere se budou vystavovat certifikaty.
WEB_DOMAIN="kramerius.docmain.cz" # check it
ADMIN_DOMAIN="kramerius-admin.domain.cz" # check it
KEYCLOAK_DOMAIN="eduid.domain.cz" # check it

for arg in "$@"; do
  case "$arg" in
    --force)
      FORCE_RENEW="true"
      ;;
    *)
      echo "Neznamy parametr: $arg"
      echo "Pouziti: $0 [--force]"
      exit 1
      ;;
  esac
done

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Tento skript je potreba spustit jako root, napr.:"
    echo "  sudo $0"
    echo
    echo "Duvod: acme.sh v rezimu --standalone potrebuje poslouchat na portu 80."
    exit 1
  fi
}

# Nainstaluje acme.sh, pokud jeste neni dostupny,
# a nastavi Let's Encrypt jako vychozi certifikacni autoritu.
ensure_acme_sh() {
  if [ ! -x "$ACME_SH" ]; then
    curl https://get.acme.sh | sh -s email="$ACME_EMAIL"
  fi

  "$ACME_SH" --set-default-ca --server "$ACME_SERVER"
}

# Vyda certifikat pro jednu domenu a nainstaluje ho do CERT_DIR.
# Prvni parametr je domena, druhy parametr je prefix nazvu souboru.
# Napriklad prefix "web" vytvori web-privkey.pem a web-fullchain.pem.
issue_and_install_cert() {
  local domain="$1"
  local cert_name="$2"

  # Argumenty pro vystaveni certifikatu pres standalone HTTP validaci.
  # Hooky si acme.sh ulozi a pouzije je znovu i pri automatickem obnovovani.
  local issue_args=(
    --issue
    --standalone
    --server "$ACME_SERVER"
    --keylength "$KEY_TYPE"
    -d "$domain"
  )

  if [ "$FORCE_RENEW" = "true" ]; then
    issue_args+=(--force)
  fi

  if [ -n "$PRE_HOOK" ]; then
    issue_args+=(--pre-hook "$PRE_HOOK")
  fi

  if [ -n "$POST_HOOK" ]; then
    issue_args+=(--post-hook "$POST_HOOK")
  fi

  # Pokud certifikat uz existuje a neni cas na obnovu, acme.sh vrati chybu
  # "Domains not changed". To ale nevadi: certifikat uz je v ACME_HOME a my
  # ho porad potrebujeme nainstalovat do CERT_DIR.
  if ! "$ACME_SH" "${issue_args[@]}"; then
    echo "Vydani/obnova certifikatu pro $domain byla preskocena nebo selhala."
    echo "Pokracuji pokusem o instalaci existujiciho certifikatu."
  fi

  # install-cert zkopiruje aktualni certifikat na misto, kde ho cte Docker proxy.
  # acme.sh si tyto cesty ulozi a po kazdem renew soubory znovu prepise.
  "$ACME_SH" --install-cert -d "$domain" \
    --ecc \
    --key-file "$CERT_DIR/$cert_name-privkey.pem" \
    --fullchain-file "$CERT_DIR/$cert_name-fullchain.pem" \
    --reloadcmd "$RELOAD_CMD"
}

# Pripravi cilovy adresar a acme.sh.
require_root
mkdir -p "$CERT_DIR"
ensure_acme_sh

# Vystavi a nainstaluje certifikaty pro jednotlive virtualhosty.
# Nazvy web/admin/keycloak odpovidaji cestam ve vhost konfiguraci Apache.
issue_and_install_cert "$WEB_DOMAIN" "web"
issue_and_install_cert "$ADMIN_DOMAIN" "admin"
issue_and_install_cert "$KEYCLOAK_DOMAIN" "keycloak"

echo "Hotovo. Certifikaty jsou nainstalovane v $CERT_DIR."
echo "acme.sh si obnovu hlida pres cron a po renew znovu spusti install-cert vcetne reloadcmd."
