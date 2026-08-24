# MetaCore — Rationale

## What deviation / exception is being requested

1. `metacore-app` runs `privileged: true` and `user: 0:0`.
2. It mounts two broad slices of the user's data area, read-only:
   `/DATA/Downloads` and `/DATA/Media`.
3. `/health` bypasses the SSO gate and is proxied straight to the backend.

## Why it is necessary

1. MetaCore is the MetaMesh infrastructure container: it runs nginx, Redis and — the
   load-bearing part — **rclone remote mounts** (NFS, SMB, S3, WebDAV) that the user adds
   from the dashboard. Creating a mount namespace inside the container needs `SYS_ADMIN`
   and `/dev/fuse`; the image also runs several supervised daemons that bind their own
   sockets. Neither works from an unprivileged, uid-1000 process.
2. MetaCore is the file watcher for the whole ecosystem. It has to see the directories a
   user actually drops media into, which are exactly `/DATA/Downloads` and `/DATA/Media`.
   There is no narrower path that satisfies the feature.
3. Sibling MetaMesh apps and the PCS health probe need an unauthenticated liveness
   endpoint; routing it to the backend keeps the tile's health independent of whether
   Authelia is up.

## Security mitigations in place

- **Both user-data mounts are `:ro`.** MetaCore reads and indexes; it cannot write to,
  rename or delete anything under `/DATA/Downloads` or `/DATA/Media`.
- Everything MetaCore writes lives under `/DATA/AppData/metacore/`, declared in
  `x-compose-app.folders` and owned `$PUID:$PGID`.
- The dashboard itself is behind AppShield + Authelia SSO; only `/health` is exempt, and
  it returns a liveness object with no user data in it.
- `mem_limit`/`memswap_limit` are both 768 MB, so the container is OOM-killed rather than
  driving the host into swap.

## Alternatives considered and rejected

- **Drop `privileged` for a `cap_add` list.** Tried: rclone's FUSE mounts need
  `SYS_ADMIN` plus an unconfined AppArmor profile plus `/dev/fuse`, which is most of what
  `privileged` grants, and the remaining supervised daemons still failed to start. The
  reduced form was not meaningfully smaller, and it was harder to reason about.
- **Run as `$PUID:$PGID`.** The mount syscalls fail outright.
- **Mount narrower paths than `/DATA/Downloads` / `/DATA/Media`.** These *are* the user's
  download and media roots; a subdirectory would silently miss most of their library.
- **Put `/health` behind the gate.** The PCS probe has no Authelia session, so the tile
  would show unhealthy whenever SSO was restarting.

## Data protection

User media is mounted read-only and never modified. All MetaCore state (Redis dump,
leader-election files, plugin artwork, cache) is under `/DATA/AppData/metacore/`, which is
the unit Maison archives on uninstall and restores from backup — so an uninstall/reinstall
cycle with "keep user data" comes back with metadata, posters and mounts intact. The
`plugin/` directory is a bind mount specifically so that recreating the container cannot
take published artwork with it.
