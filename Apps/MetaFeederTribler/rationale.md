# MetaFeeder · Tribler — Rationale

## What deviation / exception is being requested

1. `metafeedertribler-feeder` runs `user: 0:0`.
2. `tribler-instance` is seeded with a Tribler core API key of `changeme`.
3. `tribler-instance` runs the upstream Tribler image, which writes its state as root
   inside `/root/.Tribler`.

## Why it is necessary

1. The feeder publishes resolved records to the shared MetaCore and writes plugin artwork
   through its WebDAV endpoint; those targets are created and owned by MetaCore's
   root-running container.
2. Tribler's core exposes a localhost-style REST API and requires *some* key. The seeded
   value is a placeholder that matches the one baked into the feeder's own config, so the
   two agree out of the box and the app works immediately after installation — the
   functionality requirement in the guidelines. It is not a user credential and grants no
   access to anything beyond this Tribler core.
3. Upstream image behaviour; the state directory is bind-mounted so it survives container
   recreation.

## Security mitigations in place

- **`tribler-instance` is not on the shared `pcs` network.** It is attached to the
  app-private `metafeedertribler` bridge only, so the API on `:8085` is reachable by this
  app's own feeder and by nothing else on the box — not by another store app, and not from
  the internet. The `changeme` key never crosses a network boundary a stranger can reach.
- The feeder's configuration UI is behind AppShield + Authelia SSO
  (`ghcr.io/yundera/appshield:2.0.9`); the feeder itself carries no Caddy labels and
  publishes no host port.
- No user directories are mounted — no `/DATA/Documents`, `/DATA/Downloads`, `/DATA/Media`
  or `/DATA/Gallery`. All binds are under `/DATA/AppData/metafeedertribler/`, declared in
  `x-compose-app.folders`.
- Both config seeds in `pre-install-cmd` are guarded by `[ ! -f … ]`, so a reinstall or
  version upgrade never overwrites operator edits.
- Image tags pinned. `ghcr.io/tribler/tribler` is pinned to `v8.4.2`, the digest `:latest`
  resolved to at the time of pinning.

## Alternatives considered and rejected

- **Generate a random API key in the hook.** The Maison hook toolbox has no `openssl`;
  `od -An -N32 -tx1 /dev/urandom` would work, but the key has to be written into *two*
  files that must agree, and a partially-applied seed leaves the feeder unable to talk to
  its own core. Given the API is unreachable off the app-private network, the added
  failure mode buys nothing.
- **Put Tribler's API behind AppShield.** The feeder is a machine client; it cannot
  complete an interactive OIDC redirect.
- **Run the feeder as `$PUID:$PGID`.** Writes into MetaCore's root-owned tree fail.

## Data protection

No user media is mounted. Tribler's own state (`/root/.Tribler`), its seed config, the
feeder's cursor and the TMDB cache all live under `/DATA/AppData/metafeedertribler/`, the
unit Maison archives on uninstall and restores from backup.
