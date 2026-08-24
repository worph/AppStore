# MetaStremio — Rationale

## What deviation / exception is being requested

1. The addon endpoint is **served without an authentication gate** — no AppShield sidecar,
   the Caddy labels point straight at the container.
2. `metastremio` runs `user: 0:0`.
3. It mounts `/DATA/AppData/metacore/meta-core` — another app's AppData directory.

## Why it is necessary

1. A Stremio addon is consumed by the **Stremio client**, not by a browser. The client
   fetches `/manifest.json` and the catalog/stream endpoints over plain HTTP with no cookie
   jar, no redirect handling and no way to complete an interactive OIDC login. Putting
   AppShield in front makes the addon uninstallable in Stremio: the client receives the
   Authelia login page instead of JSON and reports the addon as invalid. This is the same
   class of exception the guidelines allow for a public endpoint.
2. MetaStremio writes its service registration into `/meta-core/services/`, a directory
   created and owned by MetaCore's root-running container.
3. `/meta-core` is the shared leader-election and service-discovery directory. MetaCore is
   a hard prerequisite of this app.

## Security mitigations in place

- The addon URL is **unguessable in practice**: it is `metastremio-<user>.<domain>`, a
  per-user hostname on the user's own PCS.
- The container mounts **no user media**. Under Architecture V3 it has no `/files` mounts
  at all; every byte it serves is fetched over WebDAV from MetaCore and is bounded by what
  MetaCore exposes.
- It writes only to `/DATA/AppData/metastremio/cache/` (transcoding segments), declared in
  `x-compose-app.folders`.
- `cpu_shares: 50`; image tag pinned.

## Alternatives considered and rejected

- **AppShield in front of everything.** Breaks the app completely — see above.
- **AppShield with `ALLOWED_PATHS` for the addon routes.** With `AUTH_HASH` inert under
  Maison, an allowed path is reachable with no credential at all, so this is the current
  arrangement with extra moving parts and a misleading "it's protected" appearance.
- **`OAUTH_RESOURCE` (OAuth 2.1 Bearer) on the addon paths.** The correct answer for
  machine clients in general, but Stremio has no OAuth support; it would still break.
- **A shared-secret path prefix in the manifest URL.** Considered as a follow-up; it moves
  the secret into a URL the user pastes around, and Stremio surfaces addon URLs in its UI.

## Data protection

MetaStremio stores no user data of its own beyond a transcoding cache that is safe to
delete. Because it is a public endpoint, the user should treat the addon URL as the access
control: anyone with it can browse the catalog the user's own MetaCore exposes. This is
stated in `tips.before_install`.
