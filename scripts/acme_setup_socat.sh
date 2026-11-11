#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ACME / Let's Encrypt - Kramerius
# ============================================================

ACME_EMAIL="kramerius@inovatika.cz"
CERT_DIR="/data/kramerius/mnt/containers/kramerius_httpd_proxy/certs"

ACME_HOME="/root/.acme.sh"
ACME_SH="$ACME_HOME/acme.sh"

ACME_SERVER="letsencrypt"
KEY_TYPE="ec-256"

PROXY_CONTAINER="kramerius_httpd_proxy"

FORCE_RENEW="false"
ERRORS=0

# Domeny a prefixy vystupnich souboru.
# Poradi je zamerne: Keycloak ma nejvyssi prioritu.

DOMAINS=(
  "eduid.domain.cz:keycloak"
  "kramerius-admin.domain.cz:admin"
  "kramerius.domain.cz:web"
)

# ============================================================
# Argumenty
# ============================================================

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

# ============================================================
# Pomocne funkce
# ============================================================

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Skript musi byt spusten jako root."
    exit 1
  fi
}

container_exists() {
  docker container inspect "$PROXY_CONTAINER" >/dev/null 2>&1
}

container_running() {
  [ "$(docker inspect -f '{{.State.Running}}' "$PROXY_CONTAINER" 2>/dev/null)" = "true" ]
}

stop_proxy() {
  if container_exists && container_running; then
    log "Zastavuji Docker proxy: $PROXY_CONTAINER"
    docker stop "$PROXY_CONTAINER"
  fi
}

start_proxy() {
  if container_exists; then
    if ! container_running; then
      log "Spoustim Docker proxy: $PROXY_CONTAINER"
      docker start "$PROXY_CONTAINER"
    fi
  else
    log "Docker proxy zatim neexistuje."
  fi
}

reload_proxy() {
  if container_exists && container_running; then
    log "Restartuji Docker proxy."
    docker restart "$PROXY_CONTAINER"
  fi
}

# ============================================================
# Kontrola prostredi
# ============================================================

require_root

if ! command -v docker >/dev/null 2>&1; then
  log "CHYBA: Docker neni dostupny."
  exit 1
fi

if ! command -v socat >/dev/null 2>&1; then
  log "CHYBA: socat neni nainstalovany."
  log "Nainstaluj: apt install socat"
  exit 1
fi

mkdir -p "$CERT_DIR"
chmod 755 "$CERT_DIR"

if [ ! -x "$ACME_SH" ]; then
  log "Instaluji acme.sh"
  curl -fsSL https://get.acme.sh | sh -s email="$ACME_EMAIL"
fi

"$ACME_SH" --set-default-ca --server "$ACME_SERVER"

# ============================================================
# Automaticke obnovovani
# ============================================================

# Hooky se ukladaji do konfigurace kazde domeny.
# Pri automaticke obnove acme.sh zastavi proxy pred HTTP-01
# validaci a po jejim dokonceni proxy znovu spusti.

PRE_HOOK="docker container inspect $PROXY_CONTAINER >/dev/null 2>&1 && docker stop $PROXY_CONTAINER || true"

POST_HOOK="docker container inspect $PROXY_CONTAINER >/dev/null 2>&1 && docker start $PROXY_CONTAINER || true"

RELOAD_CMD="docker container inspect $PROXY_CONTAINER >/dev/null 2>&1 && docker restart $PROXY_CONTAINER || true"

# ============================================================
# Vydani a instalace certifikatu
# ============================================================

issue_and_install_cert() {

  local domain="$1"
  local cert_name="$2"

  log "=================================================="
  log "Zpracovavam domenu: $domain"
  log "=================================================="

  local issue_args=(
    --issue
    --standalone
    --listen-v4
    --server "$ACME_SERVER"
    --keylength "$KEY_TYPE"
    --pre-hook "$PRE_HOOK"
    --post-hook "$POST_HOOK"
    -d "$domain"
  )

  if [ "$FORCE_RENEW" = "true" ]; then
    issue_args+=(--force)
  fi

  # Proxy zastavujeme explicitne, aby byl port 80
  # volny i pri prvnim vydani certifikatu.

  stop_proxy

  if "$ACME_SH" "${issue_args[@]}"; then
    log "Vydani/obnova pro $domain probehla uspesne."
  else
    log "UPOZORNENI: acme.sh nevydal novy certifikat pro $domain."
  fi

  # Overeni existence a platnosti certifikatu.

  local source_cert="$ACME_HOME/${domain}_ecc/fullchain.cer"

  if [ ! -s "$source_cert" ]; then
    log "CHYBA: Certifikat pro $domain neexistuje."
    ERRORS=$((ERRORS + 1))
    return 1
  fi

  if ! openssl x509 -in "$source_cert" -noout -checkend 604800 >/dev/null 2>&1; then
    log "CHYBA: Certifikat pro $domain neni platny alespon 7 dni."
    ERRORS=$((ERRORS + 1))
    return 1
  fi

  log "Certifikat je platny. Instaluji do $CERT_DIR."

  if "$ACME_SH" --install-cert \
    -d "$domain" \
    --ecc \
    --key-file "$CERT_DIR/$cert_name-privkey.pem" \
    --fullchain-file "$CERT_DIR/$cert_name-fullchain.pem" \
    --reloadcmd "$RELOAD_CMD"; then

    chmod 600 "$CERT_DIR/$cert_name-privkey.pem"
    chmod 644 "$CERT_DIR/$cert_name-fullchain.pem"

    log "Certifikat pro $domain byl uspesne nainstalovan."

  else
    log "CHYBA: Instalace certifikatu pro $domain selhala."
    ERRORS=$((ERRORS + 1))
    return 1
  fi

  return 0
}

# ============================================================
# Hlavni cast
# ============================================================

log "Zahajuji zpracovani SSL certifikatu."

# Pri ukonceni skriptu se pokusime proxy znovu spustit.
trap 'start_proxy || true' EXIT

for entry in "${DOMAINS[@]}"; do

  domain="${entry%%:*}"
  cert_name="${entry##*:}"

  issue_and_install_cert "$domain" "$cert_name" || true

done

# Proxy spustime az po zpracovani vsech domen.
start_proxy || ERRORS=$((ERRORS + 1))

log "=================================================="

if [ "$ERRORS" -eq 0 ]; then
  log "HOTOVO: Vsechny certifikaty byly zpracovany."
else
  log "DOKONCENO S CHYBAMI: Pocet chyb: $ERRORS"
fi

log "Certifikaty jsou v: $CERT_DIR"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
