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

* manifestType ^short = "Logical model that defines this publish manifest"
* manifestType ^definition = "Canonical reference to the logical model that defines the structure of this publish manifest. When populated, the canonical SHALL include the version of the logical model, e.g., `http://hl7.org/fhir/uv/bulkdata/StructureDefinition/BulkPublishManifest|4.0.0`. When this element is omitted, a manifest returned from `$bulk-publish`, or retrieved by following a link from such a manifest, SHALL be interpreted as a Bulk Publish Manifest. This element will be mandatory in a future release of this IG."
* transactionTime ^short = "Timestamp for the data included in this manifest"
* transactionTime ^definition = "Indicates the Data Provider's time when the files in this published manifest were generated. The published files referenced in this manifest SHOULD NOT include any resources modified after this instant. Together with the files referenced by any preceding pages in the manifest chain, they SHALL reflect all changes to the published dataset up to and including this instant."
* requiresAccessToken ^short = "Token required to retrieve published files"
* requiresAccessToken ^definition = "Indicates whether downloading the files referenced in this manifest requires an OAuth 2.0 access token obtained as described in [Authorization](authorization.html). Value SHALL be true when the published file endpoints control access using OAuth 2.0 bearer tokens. Value MAY be false when files are exposed through other access-control schemes such as capability URLs or verifiable file servers within an organization's firewall."
* outputFormat ^short = "MIME type of the referenced published files"
* outputFormat ^definition = "MIME type of the published files referenced in this manifest. Defaults to application/fhir+ndjson when omitted. Describes the expected format of the published files."
* output.url ^short = "File URL"
* output.url ^definition = "The absolute path to the file. The format of the file SHOULD match the outputFormat element in this manifest when that element is populated."
* deleted ^definition = "References to files identifying resources that the Data Provider is requesting the Data Consumer to remove from its local dataset. See [Deleted Resources](publish.html#deleted-resources)."

* link 0..1
* link ^short = "Next manifest page or update-chain marker"
* link ^definition = "When present, a single link with relation `next` points to another manifest page, an incremental update manifest page, or a pending or closed update-chain marker."
* link.url ^short = "Next manifest page or marker URL"
* link.url ^definition = "URL pointing to another manifest page, or to an operation-defined marker such as `#pending` or `#closed`."
* link.relation ^definition = "The relationship type. Value SHALL be 'next', indicating the URL points to another manifest page or to an update-chain marker such as `#pending` or `#closed`."
