import copy
import os
from urllib.parse import quote

import requests


# --- KONFIGURACE ---
KC_URL = os.getenv("KC_URL", "https://eduid.zzzz.cz").rstrip("/")

REALM = os.getenv("KC_REALM", "kramerius")
KC_USER = os.getenv("KC_USER", "keycloakAdmin")
KC_PASS = os.getenv("KC_PASS", "keycloakAdmin")
UPDATE_EXISTING = os.getenv("UPDATE_EXISTING", "false").lower() in {"1", "true", "yes", "y"}
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "30"))


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
            # Refresh token can expire too. In that case get a fresh token
            # with the configured admin credentials and retry the API call.
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


MAPPERS_TO_ADD = [
    {"name": "schacHomeOrganization", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "schacHomeOrganization", "attribute.friendly.name": "schacHomeOrganization", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:1.3.6.1.4.1.25178.1.2.9"}},
    {"name": "DNNTUsersMapper", "identityProviderAlias": "", "identityProviderMapper": "saml-advanced-role-idp-mapper", "config": {"syncMode": "FORCE", "attributes": "[{\"key\":\"eduPersonScopedAffiliation\",\"value\":\".*member.*\"},{\"key\":\"eduPersonEntitlement\",\"value\":\"urn:mace:dir:entitlement:common-lib-terms\"}]", "are.attribute.values.regex": "true", "role": "dnnt_users"}},
    {"name": "firstname importer", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "firstName", "is.required": "true", "attribute.friendly.name": "givenName", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:2.5.4.42"}},
    {"name": "eduPersonUniqueId", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "eduPersonUniqueId", "is.required": "true", "attribute.friendly.name": "eduPersonUniqueId", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:1.3.6.1.4.1.5923.1.1.1.13"}},
    {"name": "email importer", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "email", "attribute.friendly.name": "mail", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:0.9.2342.19200300.100.1.3"}},
    {"name": "displayName", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "displayName", "attribute.friendly.name": "displayName", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:2.16.840.1.113730.3.1.241"}},
    {"name": "eduPersonScopedAffiliation", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "eduPersonScopedAffiliation", "is.required": "true", "attribute.friendly.name": "eduPersonScopedAffiliation", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:1.3.6.1.4.1.5923.1.1.1.9"}},
    {"name": "username", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "INHERIT", "user.attribute": "username", "is.required": "true", "attribute.friendly.name": "eduPersonUniqueId", "attribute.name.format": "ATTRIBUTE_FORMAT_BASIC", "attribute.name": "urn:oid:1.3.6.1.4.1.5923.1.1.1.13"}},
    {"name": "eduPersonPrincipalName", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "eduPersonPrincipalName", "attribute.friendly.name": "eduPersonPrincipalName", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:1.3.6.1.4.1.5923.1.1.1.6"}},
    {"name": "eduPersonAffiliation", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "eduPersonAffiliation", "is.required": "true", "attribute.friendly.name": "eduPersonAffiliation", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:1.3.6.1.4.1.5923.1.1.1.1"}},
    {"name": "eduPersonEntitlement", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "eduPersonEntitlement", "attribute.friendly.name": "eduPersonEntitlement", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:1.3.6.1.4.1.5923.1.1.1.7"}},
    {"name": "cn", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "cn", "attribute.friendly.name": "cn", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:2.5.4.3"}},
    {"name": "lastname importer", "identityProviderAlias": "", "identityProviderMapper": "saml-user-attribute-idp-mapper", "config": {"syncMode": "FORCE", "user.attribute": "lastName", "is.required": "true", "attribute.friendly.name": "sn", "attribute.name.format": "ATTRIBUTE_FORMAT_URI", "attribute.name": "urn:oid:2.5.4.4"}},
    {"name": "DNNTWalkInMapper", "identityProviderAlias": "", "identityProviderMapper": "saml-advanced-role-idp-mapper", "config": {"syncMode": "FORCE", "attributes": "[{\"key\":\"eduPersonEntitlement\",\"value\":\"urn:mace:dir:entitlement:common-lib-terms\"},{\"key\":\"eduPersonScopedAffiliation\",\"value\":\".*walk-in.*\"}]", "are.attribute.values.regex": "true", "role": "dnnt_users"}},
    {"name": "UsersType", "identityProviderAlias": "", "identityProviderMapper": "hardcoded-attribute-idp-mapper", "config": {"syncMode": "INHERIT", "attribute.value": "eduid", "attribute": "type"}},
]


def run_sync():
    print("Získávám token...")
    client = KeycloakAdminClient(KC_URL, KC_USER, KC_PASS)
    client.login()

    providers = client.request_json(
        "GET",
        f"{KC_URL}/admin/realms/{REALM}/identity-provider/instances?first=0&max=500",
    )

    for provider in providers:
        alias = provider["alias"]
        if provider["providerId"] != "saml":
            continue

        print(f"Synchronizuji: {alias}")

        encoded_alias = quote(alias, safe="")
        existing_url = f"{KC_URL}/admin/realms/{REALM}/identity-provider/instances/{encoded_alias}/mappers"
        existing = client.request_json("GET", existing_url)
        existing_by_name = {mapper["name"]: mapper for mapper in existing}

        for mapper in MAPPERS_TO_ADD:
            data = copy.deepcopy(mapper)
            data.pop("id", None)
            data["identityProviderAlias"] = alias

            name = data["name"]

            if name in existing_by_name:
                if not UPDATE_EXISTING:
                    print(f"  - Mapper '{name}' již existuje (přeskočeno)")
                    continue

                mapper_id = existing_by_name[name]["id"]
                data["id"] = mapper_id
                put_url = f"{existing_url}/{quote(mapper_id, safe='')}"
                response = client.request("PUT", put_url, json=data)
                if response.status_code in (200, 204):
                    print(f"  ~ Mapper '{name}' aktualizován")
                else:
                    print(f"  ! Chyba při update '{name}': {response.status_code} - {response.text}")
            else:
                response = client.request("POST", existing_url, json=data)
                if response.status_code == 201:
                    print(f"  + Mapper '{name}' přidán")
                else:
                    print(f"  ! Chyba u '{name}': {response.status_code} - {response.text}")


if __name__ == "__main__":
    run_sync()
