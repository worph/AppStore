# MetaGateway (shared backend) — Rationale

## What deviation / exception is being requested

1. `metagateway-card` runs as `10001:999` rather than `$PUID:$PGID`.
2. The stack reuses the **standalone MetaCore and MetaShare apps'** services over the shared
   `pcs` network instead of bundling its own.
3. The compose top-level `name:` is `metagateway`, the same project id as the
   self-contained `MetaGateway` app in this store.

## Why it is necessary

1. `10001:999` is the uid/gid the upstream meta-feeder-card image runs its application as;
   its writable paths are baked to that owner. `/DATA/AppData/metagateway/card` is declared
   in `x-compose-app.folders` with `user: 10001` / `group: 999` so Maison creates it with
   the right ownership before the first start, instead of Compose creating it root-owned and
   the container failing on its first write.
2. This is the point of the variant: on a box that already runs MetaCore and MetaShare,
   bundling a second Redis, leader-election tier and transport peer wastes memory and
   splits the record store in two.
3. The two variants are alternatives, not companions — they share the project id and the
   same `/DATA/AppData/metagateway/` paths precisely so that installing one over the other
   reuses the same data rather than orphaning it. Exactly one may be installed at a time;
   this is stated in `tips.before_install`.

## Security mitigations in place

- Public ingress terminates at the AppShield sidecar (`ghcr.io/yundera/appshield:2.0.9`)
  behind the PCS's Authelia SSO. The backends carry no Caddy labels and publish no host
  port.
- No user directories are mounted — no `/DATA/Documents`, `/DATA/Downloads`, `/DATA/Media`
  or `/DATA/Gallery`.
- All binds are under `/DATA/AppData/metagateway/`, declared in `x-compose-app.folders`.
- `cpu_shares` on every service; image tags pinned; no `:latest`.

## Alternatives considered and rejected

- **Run `metagateway-card` as `$PUID:$PGID`.** The upstream image's baked paths are owned by
  `10001:999`; it fails on first write.
- **`chown` the directory in a hook instead.** The guidelines are explicit that a hook's
  `mkdir`/`chown` runs in the Maison container against a host path — the wrong filesystem.
  `folders` is the supported mechanism and it runs before the first pull.
- **A distinct project id, so both variants can coexist.** They would then fight over the
  same public hostnames and the same record store; two gateways on one box is not a
  supported topology.

## Data protection

State is under `/DATA/AppData/metagateway/`, the unit Maison archives on uninstall and
restores from backup. Because both MetaGateway variants use that path, switching between
them preserves the user's configuration. The MetaCore and MetaShare data this variant reads
belong to those apps and are archived with them.
