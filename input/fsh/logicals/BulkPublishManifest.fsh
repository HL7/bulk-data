Logical: BulkPublishManifest
Parent: BulkDataManifest
Id: BulkPublishManifest
Title: "Bulk Publish Manifest"
Description: "Logical model describing the manifest returned by a $bulk-publish endpoint. Extends BulkDataManifest with fields to support incremental updates through epochs and to advertise a Data Provider's expected update cadence."
* ^status = #active
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 2
* ^jurisdiction = $m49.htm#001 "World"

// Bulk Publish does not support partial-manifest pagination.
* link 0..0
* request 0..0

* transactionTime ^short = "Timestamp for the data included in this manifest"
* transactionTime ^definition = "Indicates the Data Provider's time when the files in this published manifest were generated. The published files referenced in this manifest SHOULD NOT include any resources modified after this instant, and SHALL include any matching resources modified up to and including this instant."
* requiresAccessToken ^short = "Token required to retrieve published files"
* requiresAccessToken ^definition = "Indicates whether downloading the files referenced in this manifest requires the same authorization mechanism as access to the manifest itself. Value SHALL be true when both the manifest endpoint and published file endpoints control access using OAuth 2.0 bearer tokens. Value MAY be false when files are exposed through other access-control schemes such as capability URLs or verifiable file servers within an organization's firewall."
* outputFormat ^short = "MIME type of the referenced published files"
* outputFormat ^definition = "MIME type of the published files referenced in this manifest. Defaults to application/fhir+ndjson when omitted. Describes the format Data Consumers should expect when retrieving published files."
* output.url ^short = "File URL"
* output.url ^definition = "The absolute path to the file. The format of the file SHOULD match the outputFormat element in this manifest when that element is populated."

* epochStartTime 0..1 instant "Epoch Start Time" "The timestamp when the current epoch began, used to support incremental manifest updates. When the epoch changes, epochStartTime and transactionTime SHALL be identical. Within an epoch, file lists in output, deleted, and error are append-only and file contents are immutable; an epoch reset establishes a new baseline by regenerating a complete snapshot. Data Providers that incrementally update a manifest and periodically reset to a snapshot SHALL populate this element. Data Providers that always return a complete snapshot MAY populate or omit this element."
* updateCadence 0..1 string "Update Cadence" "ISO 8601 duration indicating the typical rate at which new files will be added to the manifest (e.g., \"PT1H\"). When provided Data Consumers SHOULD use this value to choose a polling interval for subsequent requests."
