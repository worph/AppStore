# MetaFuse — Rationale

## What deviation / exception is being requested

1. `metafuse-app` runs `privileged: true`, `user: 0:0`, with `/dev/fuse`,
   `cap_add: [SYS_ADMIN, DAC_READ_SEARCH, DAC_OVERRIDE]` and `apparmor:unconfined`.
2. It mounts `/DATA/MetaFuse/Library`, which is outside both
   `/DATA/AppData/metafuse/` and the standard user directories, with `shared` mount
   propagation.
3. It mounts `/DATA/AppData/metacore/meta-core` — another app's AppData directory.
4. `/webdav*` bypasses the SSO gate.

## Why it is necessary

1. MetaFuse *is* a FUSE filesystem. Mounting one from inside a container requires
   `/dev/fuse`, `SYS_ADMIN`, and an unconfined AppArmor profile; the `DAC_*` caps let the
   filesystem answer `getattr`/`open` for files owned by other uids. There is no
   unprivileged path to this feature.
2. `shared` propagation is what makes the mount visible on the **host** at
   `/DATA/MetaFuse/Library` instead of dying inside the container's namespace. That host
   path is the entire point of the app: it is the directory the user (and Jellyfin, Plex,
   Samba, …) browse. It is deliberately *not* under `/DATA/AppData/` because it is
   user-facing content, not application state.
3. `/meta-core` is MetaCore's service-discovery and leader-election directory. MetaMesh
   apps coordinate through it; MetaFuse writes its own service registration there and
   reads the current leader. MetaCore is a hard prerequisite of this app.
4. WebDAV clients (media servers, file managers) authenticate at the WebDAV layer and
   cannot complete an interactive OIDC redirect.

## Security mitigations in place

- The interactive dashboard is behind AppShield + Authelia SSO
  (`ghcr.io/yundera/appshield:2.0.9`). Only `/health` and `/webdav*` are exempt.
- `/DATA/MetaFuse/Library` is a **virtual** view: it projects records already held by
  MetaCore. It is not a second copy of the user's library and holds no independent data.
- Everything MetaFuse persists is under `/DATA/AppData/metafuse/config/`, declared in
  `x-compose-app.folders`.
- Image tags pinned; `cpu_shares` set on both services.

## Alternatives considered and rejected

- **Unprivileged FUSE (`fusermount` with `user_allow_other`).** The container still needs
  `/dev/fuse` and `SYS_ADMIN` to create the mount namespace; dropping `privileged` left
  the mount failing at startup.
- **Mount under `/DATA/AppData/metafuse/Library`.** It would work, but the resulting path
  is not somewhere a user is expected to browse, and other apps' file pickers hide
  `AppData`. The whole feature is "a library folder you can open".
- **Put `/webdav*` behind the SSO gate.** Every non-browser WebDAV client then fails to
  authenticate, which removes the reason the endpoint exists.
- **Bundle a private MetaCore.** Duplicates the Redis/leader tier per app and breaks the
  single-source-of-truth model the ecosystem is built on.

## Data protection

MetaFuse stores no user media of its own — the library it exposes is a projection of
MetaCore's records. Its own configuration lives in `/DATA/AppData/metafuse/config/`, inside
the folder Maison archives and restores, so uninstall/reinstall preserves it. The shared
`/meta-core` mount is read-mostly: MetaFuse writes only its own service-registration file
under `/meta-core/services/`.
