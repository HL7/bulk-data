Logical: BulkPublishManifest
Parent: BulkDataManifest
Id: BulkPublishManifest
Title: "Bulk Publish Manifest"
Description: "Logical model describing the manifest returned by a $bulk-publish endpoint. Extends BulkDataManifest with fields to support incremental updates through epochs and to advertise a Data Provider's expected update cadence."
* ^status = #draft
* ^jurisdiction = $m49.htm#001 "World"

// Bulk Publish does not support partial-manifest pagination.
* link 0..0

* epochStartTime 0..1 instant "Epoch Start Time" "The timestamp when the current epoch began, used to support incremental manifest updates. When the epoch changes, epochStartTime and transactionTime SHALL be identical. Within an epoch, file lists in output, deleted, and error are append-only and file contents are immutable; an epoch reset establishes a new baseline by regenerating a complete snapshot. Data Providers that incrementally update a manifest and periodically reset to a snapshot SHALL populate this element. Data Providers that always return a complete snapshot MAY populate or omit this element."
* updateCadence 0..1 string "Update Cadence" "ISO 8601 duration indicating the typical rate at which new files will be added to the manifest (e.g., \"PT1H\"). When provided Data Consumers SHOULD use this value to choose a polling interval for subsequent requests."
