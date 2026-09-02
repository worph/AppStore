# MetaFeeder · Comic

The **literature tier** for MetaMesh: comics and manga. Two feeders plus the
aggregator they read, in one app because they are useless apart.

| container | role |
| --- | --- |
| `metafeedercomic-anilist` | **identity tier** — AniList names the *work* (title, cover, synopsis, reading direction, the anchoring id). Keyless, no config. |
| `metafeedercomic-suwayomi` | **Suwayomi (Tachidesk)** — where you install source extensions |
| `metafeedercomic-feeder` | **retrieval tier** — turns an AniList id into chapters from those sources |
| `metafeedercomic` | AppShield/OIDC gate onto Suwayomi's own UI |

## Why they ship together

A chapter record is stamped with the AniList id so several sources converge on
**one** work page instead of fragmenting into one tile per romanisation.
AniList's record for Frieren carries three different titles; three sources would
otherwise make three works. One without the other gives you covers with nothing
behind them, or chapters that never group.

## You own the sources

Suwayomi ships exactly one built-in source — *Local source*, reading CBZ/CBR
from its own folder. Everything else is an extension **you** install through its
UI. That keeps the scraping and the legal surface outside MetaMesh, exactly as
MetaFeeder · Indexer keeps indexers outside it.

Drop files into `/DATA/AppData/metafeedercomic/suwayomi/local/<Series Name>/`
and the Local source picks them up with no extension. Name the folder as AniList
knows the series, or the anchor cannot match it.

⚠ **Querying Suwayomi writes to it** — its search and chapter calls are GraphQL
mutations that cache results into its library database. Inherent to the design.

## Setup

Register **both** feeders in MetaGateway's *Add a feeder* box:

```
anilist-feeder    http://metafeedercomic-anilist:8080
suwayomi-feeder   http://metafeedercomic-feeder:8080
```

Discovery is **startup-only** — the gateway restarts itself afterwards.

## ⚠ Version pairing

`meta-feeder-suwayomi` **1.0.1** emits every chapter unresolved and delivers its
page list as an `EnrichPatch`. **meta-gateway ≥ 1.0.28** is required: older
gateways drop a patch whose `Base` was de-duplicated against their own corpus —
which is every chapter of any work they have already seen — so chapters list
correctly and then cannot be opened. Pair an older gateway with feeder 1.0.0
(eager) instead.

## Lazy chapters

Listing a series' chapters costs one upstream call however long it is; fetching
a chapter's page list costs one call each (~2.3 s), so that happens only when a
reader opens it. `SUWAYOMI_WARM_CHAPTERS` (default `0`) pre-fetches the first N
per work if you would rather trade upstream traffic for first-open latency.
