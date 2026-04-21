# Hash Lock OIDC Demo — Rationale

## What this app demonstrates

The minimal compose footprint needed to put **any** HTTP backend behind Yundera's built-in
Authelia via OIDC, using `nginx-hash-lock` as a sidecar. The protected backend is
[`traefik/whoami`](https://hub.docker.com/r/traefik/whoami) — a tiny container that
echoes the request headers — so after authenticating you can see exactly what hash-lock
forwarded to the backend (Host, X-Forwarded-*, cookies).

## Why it's useful

Anyone adding an app to the Yundera store that needs authentication in front of an
otherwise-unauthenticated service (internal dashboards, private APIs, admin UIs) can
copy this compose file, swap `whoami` for their own backend, and get:

- SSO via Authelia (shared session across all their OIDC-protected apps)
- No per-app secrets to manage — the sidecar self-registers
- Standard session cookies (httpOnly, sameSite=lax)
- OIDC authorization_code + PKCE under the hood

## Setup (the whole thing)

```yaml
environment:
  OIDC_REGISTRAR_URL: "http://auth-registrar:9092"
  BACKEND_HOST: "<your-backend-container-name>"
  BACKEND_PORT: "<your-backend-port>"
  LISTEN_PORT: "80"
```

That's it. The presence of `OIDC_REGISTRAR_URL` is what turns on OIDC mode — no
separate toggle. No `AUTH_HASH`, no `USER` / `PASSWORD`, no OIDC client IDs or
secrets. The sidecar calls `auth-registrar` on the `pcs` network at first login,
which derives the OIDC `client_id` from the container name and issues credentials.

## Deployment prerequisites

This app requires the `auth-registrar` service to be running on the PCS host's
`pcs` network. It's provisioned automatically as part of `template-root` on current
PCS versions — if `auth-registrar` isn't running, first login will fail with
`ENOTFOUND auth-registrar` in the hash-lock logs.

To verify the registrar is up before installing:

```bash
docker ps --filter name=auth-registrar --format '{{.Names}} {{.Status}}'
```

## Container naming

The `container_name: hashlockdemo` line is load-bearing — the mesh-router routes
`hashlockdemo-<user>.${APP_DOMAIN}` to the container literally named `hashlockdemo`,
and the `auth-registrar` uses that same container name as the OIDC `client_id`.
If you fork this app, keep the service name, `container_name`, `store_app_id`, and
`name` (top of file) all matching each other.

## Required assets

Before publishing to the store, add to this directory:

| File | Size | Description |
|------|------|-------------|
| `icon.png` | 192x192 px | App icon (transparent background) |
| `screenshot-1.png` | 1280x720 px | The whoami output after login — proof the sidecar is forwarding correctly |
