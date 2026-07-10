import os
import requests

# --- KONFIGURACE ---
KC_URL = os.getenv("KC_URL", "https://eduid.zzzz.cz").rstrip("/")
REALM = os.getenv("KC_REALM", "kramerius")
KC_USER = os.getenv("KC_USER", "keycloakAdmin")
KC_PASS = os.getenv("KC_PASS", "keycloakAdmin")
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "30"))

# Bezpecnostni pojistka: Pokud je True, uzivatele se pouze vypisi. 
# Pro realne mazani nastav v env: DRY_RUN=false
DRY_RUN = os.getenv("DRY_RUN", "true").lower() in {"1", "true", "yes", "y"}




class KeycloakAdminClient:
    def __init__(self, url, username, password):
        self.url = url
        self.username = username
        self.password = password
        self.access_token = None
        self.refresh_token = None
        self.headers = {"Content-Type": "application/json"}

    def login(self):
        self._set_tokens(get_admin_tokens(self.url, self.username, self.password))

    def refresh(self):
        if not self.refresh_token:
            self.login()
            return

        try:
            tokens = refresh_admin_token(self.url, self.refresh_token)
        except SystemExit:
            tokens = get_admin_tokens(self.url, self.username, self.password)
        self._set_tokens(tokens)

    def _set_tokens(self, tokens):
        self.access_token = tokens["access_token"]
        self.refresh_token = tokens.get("refresh_token")
        self.headers["Authorization"] = f"Bearer {self.access_token}"

    def request(self, method, url, **kwargs):
        kwargs.setdefault("headers", self.headers)
        response = requests.request(method, url, timeout=REQUEST_TIMEOUT, **kwargs)
        if response.status_code == 401:
            print("  ! Token vratil 401, obnovuji token a opakuji request...")
            self.refresh()
            kwargs["headers"] = self.headers
            response = requests.request(method, url, timeout=REQUEST_TIMEOUT, **kwargs)
        return response

    def request_json(self, method, url, **kwargs):
        response = self.request(method, url, **kwargs)
        try:
            response.raise_for_status()
        except requests.HTTPError as exc:
            raise SystemExit(f"HTTP chyba {response.status_code} pro {url}: {response.text}") from exc
        if response.content:
            return response.json()
        return None


def request_json(method, url, **kwargs):
    response = requests.request(method, url, timeout=REQUEST_TIMEOUT, **kwargs)
    try:
        response.raise_for_status()
    except requests.HTTPError as exc:
        raise SystemExit(f"HTTP chyba {response.status_code} pro {url}: {response.text}") from exc
    if response.content:
        return response.json()
    return None


def get_admin_tokens(url, username, password):
    token_url = f"{url}/realms/master/protocol/openid-connect/token"
    payload = {
        "client_id": "admin-cli",
        "grant_type": "password",
        "username": username,
        "password": password,
    }
    return request_json("POST", token_url, data=payload)


def refresh_admin_token(url, refresh_token):
    token_url = f"{url}/realms/master/protocol/openid-connect/token"
    payload = {
        "client_id": "admin-cli",
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
    }
    return request_json("POST", token_url, data=payload)


def run_cleanup():
    print("Ziskavam token...")
    client = KeycloakAdminClient(KC_URL, KC_USER, KC_PASS)
    client.login()

    if DRY_RUN:
        print("  [INFO] Skript bezi v rezimu DRY_RUN (pouze vypisuje, nemaze).")

    print(f"Hledam uzivatele v realmu '{REALM}' s atributem type=eduid...")
    
    users_url = f"{KC_URL}/admin/realms/{REALM}/users"
    users = client.request_json("GET", users_url, params={"q": "type:eduid", "max": 1000})

    if not users:
        print("  - Nebyli nalezeni zadni uzivatele odpovidajici kritériu.")
        return

    print(f"  * Nalezeno uzivatelu celkem: {len(users)}")
    print("-" * 70)

    for idx, user in enumerate(users, start=1):
        user_id = user.get("id")
        username = user.get("username")
        
        print(f"[{idx}/{len(users)}] Uzivatel: {username} (ID: {user_id})")

        if DRY_RUN:
            # V rezimu DRY_RUN jen vypiseme a jdeme dal
            continue

        # Interaktivni dotaz pro kazdeho uzivatele zvlast
        confirmation = input(f"  Chcete smazat uzivatele {username}? (yes/no): ").strip().lower()
        if confirmation not in {"yes", "y"}:
            print("  -> Preskoceno.")
            continue

        # Samotne mazani po potvrzeni
        delete_url = f"{users_url}/{user_id}"
        response = client.request("DELETE", delete_url)
        if response.status_code in (200, 204):
            print(f"  ~ Uzivatel {username} byl uspesne smazan.")
        else:
            print(f"  ! Chyba pri mazani {username}: {response.status_code} - {response.text}")

    print("-" * 70)
    if DRY_RUN:
        print("Konec vypisu. Pro interaktivni mazani spustte skript s DRY_RUN=false.")
    else:
        print("Proces byl dokoncen.")


if __name__ == "__main__":
    run_cleanup()