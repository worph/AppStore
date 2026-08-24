# MetaSort — Rationale

## What deviation / exception is being requested

1. `metasort-app` runs `user: 0:0`.
2. It mounts the Docker socket, `/var/run/docker.sock`, read-only.
3. It mounts `/DATA/AppData/metacore/meta-core` — another app's AppData directory.

## Why it is necessary

1. MetaSort writes its service registration into `/meta-core/services/`, a directory
   created and owned by MetaCore's root-running container, and runs nginx internally.
2. MetaSort's enrichment plugins are **containers**. It lists, starts and stops them on the
   `pcs` network (`CONTAINER_NETWORK=pcs`), and receives their results on
   `CONTAINER_CALLBACK_URL`. Driving container lifecycle requires the Docker API.
3. `/meta-core` is the shared leader-election and service-discovery directory. MetaCore is
   a hard prerequisite of this app.

## Security mitigations in place

- **The socket is mounted `:ro`.** That limits the *bind*, not the API — a read-only socket
  bind still permits write calls — so the meaningful control is the perimeter: the
  container carries no Caddy labels, publishes no host port, and is reachable only from
  the `pcs` network.
- Public ingress terminates at the AppShield sidecar (`ghcr.io/yundera/appshield:2.0.9`)
  behind Authelia SSO; only `/health` is exempt.
- MetaSort's own state is confined to `/DATA/AppData/metasort/cache/`, declared in
  `x-compose-app.folders`.
- `cpu_shares` set on both services; image tags pinned.

## Alternatives considered and rejected

- **A Docker-socket proxy (e.g. tecnativa/docker-socket-proxy) allowing only the endpoints
  MetaSort uses.** This is the right long-term shape and is the intended follow-up. It is
  not shipped here because plugin lifecycle needs `containers`, `images`, `exec` and
  `networks` write access, which is most of the API surface anyway; the proxy would narrow
  the blast radius without eliminating it.
- **Run plugins as sibling compose services instead of on-demand containers.** Plugins are
  installed and removed by the user at runtime; a static compose file cannot express that.
- **Run as `$PUID:$PGID`.** Fails writing into MetaCore's root-owned
  `/meta-core/services/`.

## Data protection

MetaSort holds no user media — it reads metadata through MetaCore and caches derived data
under `/DATA/AppData/metasort/cache/`, which Maison archives and restores. Its access to the
user's files is indirect, through MetaCore's WebDAV endpoint, and is bounded by what
MetaCore itself exposes (read-only mounts of `/DATA/Downloads` and `/DATA/Media`).
