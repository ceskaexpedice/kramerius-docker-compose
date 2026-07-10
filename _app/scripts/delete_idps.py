import os
from urllib.parse import quote

import requests


# --- KONFIGURACE ---
KC_URL = os.getenv("KC_URL", "https://eduid.zzz.cz/").rstrip("/")


REALM = os.getenv("KC_REALM", "kramerius")
KC_USER = os.getenv("KC_USER", "keycloakAdmin")
KC_PASS = os.getenv("KC_PASS", "keycloakAdmin")
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "30"))

# Bez DELETE_IDPS_CONFIRM=true skript jen vypise, co by smazal.
DELETE_IDPS_CONFIRM = os.getenv("DELETE_IDPS_CONFIRM", "false").lower() in {
    "1",
    "true",
    "yes",
    "y",
}

# Volitelne lze mazat jen konkretni typ provideru, napr. KC_PROVIDER_ID=saml.
KC_PROVIDER_ID = os.getenv("KC_PROVIDER_ID", "").strip()


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


def run_delete():
    print("Ziskavam token...")
    client = KeycloakAdminClient(KC_URL, KC_USER, KC_PASS)
    client.login()

    providers = client.request_json(
        "GET",
        f"{KC_URL}/admin/realms/{REALM}/identity-provider/instances?first=0&max=500",
    )

    if KC_PROVIDER_ID:
        providers = [provider for provider in providers if provider.get("providerId") == KC_PROVIDER_ID]

    if not providers:
        print("Nenalezen zadny identity provider ke smazani.")
        return

    print(f"Nalezeno IDP ke smazani: {len(providers)}")
    if not DELETE_IDPS_CONFIRM:
        print("Dry-run rezim. Pro skutecne smazani nastav DELETE_IDPS_CONFIRM=true.")

    for provider in providers:
        alias = provider["alias"]
        provider_id = provider.get("providerId", "")
        print(f"  - {alias} ({provider_id})")

        if not DELETE_IDPS_CONFIRM:
            continue

        encoded_alias = quote(alias, safe="")
        delete_url = f"{KC_URL}/admin/realms/{REALM}/identity-provider/instances/{encoded_alias}"
        response = client.request("DELETE", delete_url)
        if response.status_code in (200, 204):
            print(f"    smazano")
        else:
            print(f"    chyba pri mazani: {response.status_code} - {response.text}")


if __name__ == "__main__":
    run_delete()
