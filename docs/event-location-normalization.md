# Event location normalization

Events now reference saved_locations through a required foreign key. The location label and optional pin live only in saved_locations. Event.name remains the event title; SavedLocation.name is the venue label.

is_saved marks locations offered in the reusable venue picker. Existing saved venues retain true; backfilled event-only locations and newly entered venues use false. Name uniqueness applies only to reusable venues. Venues without a pin remain supported for imports and map outages; proximity check-in still requires both coordinates.

The Event location/latitude/longitude accessors preserve the existing forms, import mapper and check-in service interface without storing duplicate columns. Edits copy a persisted location before changing it, preserving other events and saved venue templates. Unreferenced locations are retained, not deleted automatically.

## Deployment

Review this branch before merging. Back up the database, pause app writes, deploy the matching application release and run rails db:migrate before resuming traffic. Do not run this migration against an old app release: the old event columns are removed. The migration runs transactionally on PostgreSQL and preserves exact matching names and pins; same labels with different pins remain separate. Rollback requires restoring the database backup with the previous app release; db:rollback is deliberately blocked.

## Relationships

No new join table is needed: each event belongs to one location and a location can have many events. Existing attendances connects members and events (and can reference an awarded point). points connects members, requirements and semesters. event_submissions connects members, requirements, reviewer members and optional points. A SQL JOIN is an operation, not an additional table.

## Verification

RSpec covers normalized storage, unpinned venues, editing shared locations, invalid coordinates and referenced-location deletion. The migration test exercises existing saved venues, matching event pins, a conflicting pin under the same label and an unpinned venue. Existing request/import/check-in specs continue exercising the public behavior. No production migration or merge has been performed.
