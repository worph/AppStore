# MetaRead

Reading client for the decentralized **MetaMesh** network — comics and manga,
books, papers and scanned documents. The third client after MetaWatch (video)
and MetaListen (audio), built the same way.

## What's in the stack

**Self-contained** (mirrors `packages/meta-read/dev/`). It does **not** depend
on the standalone MetaCore app — it ships its own infra so it runs alongside
MetaGateway and the other Meta* apps with no collisions:

| container | role |
| --- | --- |
| `metaread-core` | identity keystore, User Data Layer op-log, ingested records |
| `metaread-search` | discovery — federated search, gateway fan-out, cover recovery |
| `metaread-share` | pure content transport — byte Range, bitswap, BitTorrent |
| `metaread-app` | the reader UI/back-end |
| `metaread` | AppShield/OIDC gate (plus `metareadshare`, `metareadsearch` for the peer chips) |

⚠ **Host ports 4005 / 4006.** MetaWatch already publishes 4003/4004. Two peers
cannot share a host port; walk the pairs upward for further clients.

## The reading model

The **depth of the hierarchy is a property of the item, not of the app**. A
manga is *work → volume → chapter*, with several scanlations per chapter and a
chooser between them. A Gutenberg novel is one work and one file — its page *is*
the reader entry point, and no synthetic chapter 1 is invented to pad it.

Page decoding (CBZ, CBR, EPUB, PDF) happens **in the browser**. The server is a
flat Range/206 byte proxy and never unpacks an archive on your behalf.

## It needs a feeder

MetaRead holds no catalogue. An empty library is the honest state of a mesh
nobody has fed, not a fault. Install alongside **MetaGateway** plus:

- **MetaFeeder · Suwayomi** (+ **MetaFeeder · AniList**) — for comics and manga
- **MetaFeeder · Gutenberg** — Project Gutenberg (+ Open Library cards), for public-domain books

and register each feeder in the gateway's config. Gateway feeder discovery is
**startup-only**.
