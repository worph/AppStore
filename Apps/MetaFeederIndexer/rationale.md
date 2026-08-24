# MetaFeeder · Indexer — Rationale

## What deviation / exception is being requested

`metafeederindexer-feeder` runs `user: 0:0`.

## Why it is necessary

The feeder publishes its resolved records to the shared MetaCore over HTTP and writes its
own service registration and plugin artwork through MetaCore's WebDAV endpoint. Those
writes land in directories created and owned by MetaCore's root-running container; a
uid-1000 process is refused. The feeder image also runs a small supervised process group
(fetcher + enrichment plugin clients) that expects to be able to signal its children.

## Security mitigations in place

- Public ingress terminates at the AppShield sidecar (`ghcr.io/yundera/appshield:2.0.9`),
  which gates every path behind the PCS's Authelia SSO over OIDC. The feeder carries no
  Caddy labels and publishes no host port, so it is reachable only from the `pcs` Docker
  network.
- The container mounts **no user directories** — not `/DATA/Documents`, `/DATA/Downloads`,
  `/DATA/Media` or `/DATA/Gallery`. Its only bind is its own state under
  `/DATA/AppData/metafeederindexer/`, declared in `x-compose-app.folders` and owned `$PUID:$PGID`.
- `cpu_shares` set on every service; image tags pinned; no `:latest`.
- The enrichment sidecars (`-filename-parser`, `-tmdb`) run **unprivileged** — no `user:`
  field, so Yundera starts them as `$PUID:$PGID`. `-filename-parser` is on the app-private
  `metafeederindexer` bridge only; `-tmdb` also joins `pcs` because MetaCore calls back into
  it, and it carries an app-prefixed `container_name` so it cannot collide with another
  app's service in the shared DNS namespace. Neither carries Caddy labels or publishes a
  host port.

## Alternatives considered and rejected

- **Run as `$PUID:$PGID`.** Writes into MetaCore's root-owned `/meta-core` tree and through
  its WebDAV endpoint fail, and the feeder starts but silently publishes nothing.
- **Have MetaCore relax the ownership of its shared directory.** That would loosen
  permissions for every MetaMesh app at once, which is strictly worse than one root
  container with no user-data mounts.
- **Drop privileges after startup inside the image.** Upstream change; tracked, not
  available in the shipped image.

## Data protection

The feeder holds no user media. Its entire state — configuration, cursor position, and
(where applicable) the TMDB cache — lives under `/DATA/AppData/metafeederindexer/`, which is the unit
Maison archives on uninstall and restores from backup, so an uninstall/reinstall with "keep
user data" resumes where it left off rather than re-indexing from scratch.
