# MetaWatch

Stremio-style, **video-only** client for the decentralized MetaMesh network.
Browses curated rows + filtered search, hides anything without a poster +
description, and plays back in the browser — the server does zero media work
(flat Range/206 byte proxy, no transcode).

## What's in the stack

This is a **self-contained** stack (mirrors `packages/meta-watch/dev/`). It does
**not** depend on the standalone MetaCore app — it ships its own dedicated
infra so it can run alongside MetaGateway and the other Meta* apps with no
collisions:

| Container | Role |
|-----------|------|
| `metawatch-app` | UI + back-end the browser talks to (behind OIDC) |
| `metawatch-search` | Discovery: Kamilata federated search, identity/sign chain, prefs, User Data Layer |
| `metawatch-share` | Pure content transport: byte Range, bitswap, BitTorrent tier |
| `metawatch-core` | Dedicated meta-core: identity keystore + ingested records |
| `metawatch` | nginx-hash-lock OIDC perimeter for the dashboard |

Identity rides `meta-watch → meta-search → meta-core` (meta-watch holds only
verify keys). My List + Continue Watching persist in
`/DATA/AppData/metawatch/data` via the User Data Layer op-log.

## Data layout

```
/DATA/AppData/metawatch/
├── metacore/   # shared by core + search + share (leader info, services, redis)
└── data/       # library.json + oplog.cbor (My List / Continue Watching)
```

## Federation

`metawatch-search` and `metawatch-share` join the **public** libp2p swarm
(kad-DHT, cohort `metamesh-share-default`) and host-publish their libp2p
listeners on TCP **4004** / **4003**. mDNS on the `pcs` network lets them find a
same-host MetaGateway without any open ports. To scope a private cohort, set a
matching `KAD_NAMESPACE` on every node.

## You need a content producer

MetaWatch is a *consumer*. To see anything, at least one **MetaGateway** (or
another MetaShare archivist) must be reachable on the swarm. Install
**MetaGateway** for the torznab/Prowlarr + Tribler feed.

## Images

Pulls `ghcr.io/worph/{meta-watch,meta-search,meta-share,meta-core}:1.0.0` and
`ghcr.io/yundera/nginx-hash-lock:1.0.7`. Publish the `worph/*` tags before
listing the app.
