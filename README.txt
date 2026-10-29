PT-502 migration archive

Source: https://github.com/FA26-CSCE431-software-engineering/PT-502
Destination: https://github.com/t8ctamu/pt-502

The original branches were copied without rewriting any commit. Author and
committer timestamps, time zones, commit IDs, messages, and file trees remain
unchanged. The source repository remains in place.

This separate branch holds an archival snapshot, not the application.
github-records/ includes original issue/pull-request records, comments, reviews,
commit/file lists, events, deployment records, labels, and configuration metadata.
Original identities and timestamps are recorded in JSON; GitHub's live issue and
pull-request interfaces are not recreated. See github-records/manifest.json for
capture time, counts, and limitations.

source-history.bundle contains all 240 commits reachable from the source's
branches, tags, and pull-request refs at capture time, including commits from
deleted PR branches. It can be inspected with:
  git bundle list-heads source-history.bundle
  git clone --mirror source-history.bundle recovered.git

No production database, secrets, credentials, external integrations, or project
boards were transferred. Expired Actions files cannot be recovered; archived
Actions records contain metadata only. Existing school-repository links in code
and records still point to the school original.
