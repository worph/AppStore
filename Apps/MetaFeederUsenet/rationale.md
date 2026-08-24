# MetaFeeder · Usenet — Rationale

## What deviation / exception is being requested

1. `metafeederusenet-feeder` runs `user: 0:0`.
2. The **NNTmux web UI is published on its own hostname**
   (`metafeederusenetnntmux-<user>.<domain>`) with no AppShield sidecar in front of it — it
   is protected by NNTmux's own login only.
3. The seeded `nntmux.env` contains TMDB and TVDB API keys as literals.

## Why it is necessary

1. The feeder publishes resolved records to the shared MetaCore and writes plugin artwork
   through its WebDAV endpoint; those targets are created and owned by MetaCore's
   root-running container.
2. NNTmux is a Laravel application with its own user table, session handling and admin
   role. Its admin account is created at install from `$APP_DEFAULT_PASSWORD`, so
   authentication is **enabled by default** — the "app's own built-in auth" alternative the
   security checklist accepts. Fronting it with AppShield as well would double-prompt on
   every page and breaks its own OTP and password-reset flows.
3. Those two keys are NNTmux's upstream project defaults, shipped in its own
   `.env.example`. They are shared read-only application keys for public metadata catalogs,
   not user credentials, and they are what makes the app work immediately after
   installation with no manual configuration. An operator can replace them from the NNTmux
   admin UI.

## Security mitigations in place

- The NNTmux admin password is `$APP_DEFAULT_PASSWORD` — the platform-generated secret —
  and the database password comes from the same variable. Neither is a hardcoded literal,
  and both are surfaced to the user in `tips.before_install`.
- The feeder's own configuration UI *is* behind AppShield + Authelia SSO
  (`ghcr.io/yundera/appshield:2.0.9`).
- `metafeederusenet-db`, `-redis` and `-manticore` are on the app-private
  `metafeederusenet` bridge network, carry no Caddy labels and publish no host port, so no
  sibling app on the shared `pcs` network can resolve or dial them.
- NNTP provider credentials are deliberately left **blank** in the seed; the user fills
  them in per `tips.before_install`. Nothing ships with a working news account.
- The `nntmux.env` seed is guarded by `[ ! -f … ]`, so a reinstall or version upgrade never
  overwrites the operator's provider settings. `scanner.sh` is intentionally rewritten on
  every run — it is shipped code, not operator config, so a store update must be able to
  replace a stale copy; the write is idempotent.
- No user directories are mounted. All binds are under `/DATA/AppData/metafeederusenet/`,
  declared in `x-compose-app.folders`.
- `cpu_shares` on all nine services; every image pinned (the NNTmux and Manticore images by
  digest).

## Alternatives considered and rejected

- **AppShield in front of NNTmux.** Two independent login gates on one UI; its OTP,
  password-reset and API endpoints break behind the OIDC redirect.
- **Blank the TMDB/TVDB keys.** The app then installs into a state where covers and
  metadata silently fail until the user finds two upstream registration flows — a direct
  violation of "works immediately after installation, no manual configuration required for
  basic functionality".
- **Run the feeder as `$PUID:$PGID`.** Writes into MetaCore's root-owned tree fail.

## Data protection

All state — MariaDB, the NZB store, the feeder cursor, the TMDB cache — is under
`/DATA/AppData/metafeederusenet/`, the unit Maison archives on uninstall and restores from
backup, so an uninstall/reinstall with "keep user data" comes back with the release
catalogue intact rather than re-scanning Usenet from scratch. No user media directory is
mounted into any service.
