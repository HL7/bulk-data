Logical: BulkPublishManifest
Parent: BulkDataManifest
Id: BulkPublishManifest
Title: "Bulk Publish Manifest"
Description: "Logical model describing the manifest returned by a $bulk-publish endpoint. Extends BulkDataManifest with fields to advertise a Data Provider's update cadence and support pending-based incremental update chains."
* ^status = #active
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 2
* ^jurisdiction = $m49.htm#001 "World"

* updateCadence 0..1 string "Update Cadence" "ISO 8601 duration indicating the typical rate at which the Data Provider expects the manifest or pending update-chain pages to change. When provided, Data Consumers SHOULD use this value to choose a polling interval for subsequent requests."

* transactionTime ^short = "Timestamp for the data included in this manifest"
* transactionTime ^definition = "Indicates the Data Provider's time when the files in this published manifest were generated. The published files referenced in this manifest SHOULD NOT include any resources modified after this instant, and SHALL include any matching resources modified up to and including this instant."
* requiresAccessToken ^short = "Token required to retrieve published files"
* requiresAccessToken ^definition = "Indicates whether downloading the files referenced in this manifest requires the same authorization mechanism as access to the manifest itself. Value SHALL be true when both the manifest endpoint and published file endpoints control access using OAuth 2.0 bearer tokens. Value MAY be false when files are exposed through other access-control schemes such as capability URLs or verifiable file servers within an organization's firewall."
* outputFormat ^short = "MIME type of the referenced published files"
* outputFormat ^definition = "MIME type of the published files referenced in this manifest. Defaults to application/fhir+ndjson when omitted. Describes the expected format of the published files."
* output.url ^short = "File URL"
* output.url ^definition = "The absolute path to the file. The format of the file SHOULD match the outputFormat element in this manifest when that element is populated."

* link 0..1
* link ^short = "Next manifest page or update-chain marker"
* link ^definition = "When present, a single link with relation `next` points to another manifest page, an incremental update manifest page, or a pending or closed update-chain marker."
* link.url ^short = "Next manifest page or marker URL"
* link.url ^definition = "URL pointing to another manifest page, or to an operation-defined marker such as `#pending` or `#closed`."
* request 0..0