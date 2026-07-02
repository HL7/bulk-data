Logical: BulkSubmitStatusManifest
Parent: BulkDataManifest
Id: BulkSubmitStatusManifest
Title: "Bulk Submit Status Manifest"
Description: "Logical model describing the status manifest returned by a Data Consumer in response to a $bulk-submit-status polling request. Extends BulkDataManifest with a submissionId linking the manifest to the originating submission, and a manifestUrl on output and outcome items linking them back to the Data Provider's submitted manifests."
* ^status = #active
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 2
* ^jurisdiction = $m49.htm#001 "World"

* manifestType ^short = "Logical model that defines this status manifest"
* manifestType ^definition = "Canonical URL of the logical model that defines the structure of this status manifest. E.g., `http://hl7.org/fhir/uv/bulkdata/StructureDefinition/BulkSubmitStatusManifest`. This element will be mandatory in a future release of this IG."
* transactionTime ^short = "Timestamp for the data included in this manifest"
* transactionTime ^definition = "Indicates the Data Consumer's time when this status manifest and its referenced files were generated. The returned files SHOULD NOT include resources modified after this instant, and SHALL include any matching resources prepared up to and including this instant."
* requiresAccessToken ^short = "Token required to retrieve status files"
* requiresAccessToken ^definition = "Indicates whether downloading the files referenced in this status manifest requires the same authorization mechanism as the `$bulk-submit-status` interaction that produced it. Value SHALL be true when both the Data Consumer's status endpoint and file endpoints control access using OAuth 2.0 bearer tokens. Value MAY be false for file endpoints that use other access-control schemes such as capability URLs or verifiable file servers within an organization's firewall."
* outputFormat ^short = "MIME type of the referenced status files"
* outputFormat ^definition = "MIME type of the files referenced in this status manifest. Defaults to application/fhir+ndjson when omitted. Corresponds to the `_outputFormat` parameter in the Bulk Submit Status operation."
* output.url ^short = "File URL"
* output.url ^definition = "The absolute path to the file. The format of the file SHOULD reflect that requested in the `_outputFormat` parameter of the initial `$bulk-submit-status` request and the `outputFormat` element in this manifest."

* submissionId 1..1 string "Submission Identifier" "Identifier for the submission this status manifest relates to, matching the submissionId provided by the Data Provider in the $bulk-submit kick-off request."

* output.manifestUrl 0..1 url "Source Manifest URL" "URL of the manifest submitted by the Data Provider that the resources in this output file relate to. A single manifestUrl MAY be referenced from multiple items in the output section."

* deleted ^short = "Deleted Resource Files"
* deleted ^definition = "References to files containing pointers to previously submitted resources marked for removal by the Data Provider. Each line in the deleted files SHALL contain a FHIR Bundle with a type of transaction which SHALL contain one or more entry items that reflect a deleted resource. In each entry, the request.url and request.method elements SHALL be populated and request.method SHALL be set to DELETE."

* outcome.manifestUrl 1..1 url "Source Manifest URL" "URL of the manifest submitted by the Data Provider where the issues described in this outcome file occurred. Each item in the outcome section SHALL include this element. A single manifestUrl MAY be referenced from multiple items in the outcome section."
