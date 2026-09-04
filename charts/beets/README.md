# Beets lyrics job

This chart runs Beets nightly to add missing embedded lyrics to the music
library used by Gonic. It prefers synchronized lyrics from LRCLIB and lrcmux,
falls back to plain lyrics, and never deliberately overwrites an existing
lyrics tag.

## Safety model

The job catalogs files with their existing metadata. Its import command always
uses `--noautotag`, `--nocopy`, `--nomove`, and `--nowrite`; Beets therefore
cannot reorganize the collection or rewrite tags during catalog refresh. Only
the subsequent `lyrics` command writes tags, and `lyrics.force: no` preserves
tracks that already contain lyrics. Likely DRM-protected `.m4p` files are
ignored. Tracks without enough artist/title metadata and unmatched tracks are
logged and left unchanged. The job prints catalog, existing-lyrics,
missing-artist, missing-title, query-match, and newly-added-lyrics counts on
every run.

The container runs as the Synology media owner (`1024:100`). The CronJob uses
`Forbid` concurrency and a 12-hour active deadline. Successful child Jobs are
deleted automatically; the three most recent failed Jobs are retained for
diagnosis. The Beets catalog is kept
at `/volume1/files/beets/config/library.db`; preserving it is important because
its `added` timestamps bound provider retries to newly seen tracks.

The image is an immutable LinuxServer nightly at Beets commit `63b69fa9`.
Stable 2.13.1 crashes when LRCLIB returns a duration-matched metadata record
whose plain and synchronized lyrics are both null. The pinned nightly includes
the upstream fix from beets PR #6906, rejects that empty candidate, and
continues to another candidate/provider. Replace it with the first stable
Beets release containing that fix after repeating the fixture tests.

## Prerequisites

1. Create `/volume1/files/beets/config` on the Synology and make it writable by
   UID 1024/GID 100.
2. Create a fresh snapshot of `/volume1/files/media/music` and confirm that an
   individual file can be restored from it.
3. Render and review the release before applying it:

   ```sh
   helm dependency update charts/beets
   helm lint charts/beets
   task helmfile:template RELEASE=beets SKIP_DEPS=true
   task helmfile:diff RELEASE=beets SKIP_DEPS=true
   ```

## Staged rollout

Do not start with an unattended full-library run.

1. Copy representative MP3, M4A, FLAC, and WAV files to a scratch directory.
   Run the pinned image and the exact command from `values.yaml` against those
   copies first. Verify that each file still decodes, its audio-stream checksum
   is unchanged, artwork/metadata remain, and the lyrics tag is readable. The
   implementation fixture test embedded timestamped lyrics in MP3 `USLT` and
   `SYLT`, M4A `©lyr`, and FLAC `LYRICS` without changing any audio-stream
   hash; a second run made no file changes. The pinned nightly was also tested
   against LRCLIB's empty non-instrumental result for Arion's “Cold Blood & Ice
   Cream Cones”; it completed without the stable 2.13.1 `NoneType` crash. The
   library's WAV samples do not expose artist/title tags to Beets and are
   therefore logged and skipped. M4P
   is intentionally excluded.
2. Temporarily replace `BEETS_LYRICS_QUERY` in `values.yaml` with a tested Beets
   album query selecting roughly 25 real tracks and set
   `baseResources.cronjob.suspend: true`. Apply the chart and create a one-off
   run from the managed CronJob:

   ```sh
   kubectl create job --from=cronjob/beets-beets beets-lyrics-sample -n default
   kubectl logs -n default -f job/beets-lyrics-sample
   ```

3. Inspect every changed track in a tag reader and through Gonic's
   `getLyricsBySongId` endpoint and a Subsonic client. Check both synchronized
   and plain-fallback results. Run the same query again and confirm all enriched
   tracks are skipped.
4. Restore `BEETS_LYRICS_QUERY` to `added:-7d..`, set `suspend: false`, review
   the diff, and apply it. Because all tracks are new to the initial Beets
   catalog, this performs the full backfill. Later nightly runs retry new tracks for seven days and do not
   repeatedly query providers for permanent misses.

The scheduled run is at 02:30 in `America/Indiana/Indianapolis`. Gonic also
performs an hourly scan so NFS writes made by this separate pod become visible
even when filesystem notifications do not cross NFS clients.

## Operations

Inspect the CronJob and recent runs:

```sh
kubectl get cronjob beets-beets -n default
kubectl get jobs -n default --sort-by=.metadata.creationTimestamp | tail
kubectl logs -n default job/<job-name>
```

Start the normal managed job manually:

```sh
kubectl create job --from=cronjob/beets-beets \
  "beets-lyrics-$(date +%Y%m%d%H%M%S)" -n default
```

Beets logs `Found lyrics`, `Lyrics not found`, missing metadata, write errors,
and provider rate-limit/retry failures. A failed Job remains in history. Fix
its cause and create a new run. `Forbid` prevents overlap between Jobs created
by the CronJob, but a standalone Job made with `kubectl create job --from` is
not covered; suspend the schedule or confirm no other Job is active before a
manual run.

For an intentional full retry, temporarily set `BEETS_LYRICS_QUERY` to an empty
string (all cataloged items), apply, launch one manual Job, then restore the
seven-day query. Existing lyrics remain protected. To target missing lyrics
more narrowly, use a tested Beets query and preview it with `beet ls` before
running `beet lyrics`.

## Recovery

If validation finds damaged tags or audio, suspend the CronJob, retain its logs,
and restore the affected files from the pre-rollout Synology snapshot. Remove
and recreate `/volume1/files/beets/config/library.db` only when intentionally
resetting the catalog; doing so makes every track appear newly added and causes
the next seven-day query to attempt a full backfill again.

The initial providers require no credentials. A paid/API-backed fallback can be
added later through a SOPS-encrypted Secret and `secretKeyRef`; never put API
keys directly in this chart or its ConfigMap.
