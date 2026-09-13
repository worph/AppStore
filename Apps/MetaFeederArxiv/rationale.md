# MetaFeeder · arXiv — Rationale

## What deviation / exception is being requested

`metafeederarxiv-feeder` runs `user: 0:0`.

## Why it is necessary

Carried over unchanged from the listing this app was split out of (MetaFeeder · Papers), so the
feeder behaves exactly as it did there. The MetaFeeder images write their state and
redb cache as the container user and some reach MetaCore's root-owned tree; a uid-1000
process is refused.

## Security mitigations in place

- Public ingress terminates at the AppShield sidecar (`ghcr.io/yundera/appshield:2.0.9`),
  which gates every path behind the PCS's Authelia SSO over OIDC. The feeder carries no
  Caddy labels and publishes no host port, so it is reachable only from the `pcs` Docker
  network.
- The container mounts **no user directories** — not `/DATA/Documents`, `/DATA/Downloads`,
  `/DATA/Media` or `/DATA/Gallery`. Its only bind is its own state under
  `/DATA/AppData/metafeederarxiv/`, declared in `x-compose-app.folders` and owned `$PUID:$PGID`.
- `cpu_shares` set on every service; image tags pinned; no `:latest`.

## Alternatives considered and rejected

- **Run as `$PUID:$PGID`.** Not validated for this image; switching the runtime user in
  the same change as the split would mix a behaviour change into a packaging change.

## Data protection

The feeder holds no user media. Its entire state lives under `/DATA/AppData/metafeederarxiv/`, which
is the unit Maison archives on uninstall and restores from backup.
