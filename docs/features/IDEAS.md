# Developer Ideas

Settings version number unlocks developer options after three taps. The reusable DeveloperAccess model resets the 30-second inactivity window on Settings interactions. The entry expires after that interval and resets when leaving Settings; foreground return rechecks expiry. It is ephemeral and never stored with music or Ideas. Lifecycle timing is unit-tested; physical-device lifecycle validation remains pending.

Ideas have stable UUID, title, description, category, priority, status, created/modified times and optional implementation reference. Supported statuses: pending, approved, deferred, inProgress, implemented and rejected. They persist in SQLite, isolated from music. Updates retain previous values in idea_revisions. The editor does not automatically mark work implemented.

UI supports create/edit/delete, duplicate, search, status filtering, modified-date sorting, JSON import/export and a confirmation before merging. Export uses IdeasExport schema version 1, project it.xarber.harmony, Swift Codable Date encoding (seconds since 2001-01-01 UTC) and ideas. The project's docs/IDEAS.json uses the same format. Imports validate schema/project/unique IDs and add only new IDs; existing IDs are preserved. A detailed incoming conflict comparison, bulk selection, user-selectable sort, screenshot attachments, Markdown export and a revision history UI are not yet implemented.

AGENTS.md requires checking repository ideas at session start, reporting relevant counts, offering optional ideas now/later and preserving unselected entries. Initial collection: empty. Private on-device ideas require an authorized export; no automatic repository synchronization or privileged device-storage access exists.

Changelog metadata has an ideaIDs field. Current entries have no implemented idea IDs because no user-recorded feature idea was selected and completed. Implementation references remain available for future commit/version links. Automatic commit matching and changelog navigation from individual ideas are pending.
