Logical: BulkSubmitStatusManifest
Parent: BulkDataManifest
Id: BulkSubmitStatusManifest
Title: "Bulk Submit Manifest"
Description: "Logical model describing the status manifest returned by a Data Recipient in response to a $bulk-submit-status polling request. Extends BulkDataManifest with a submissionId linking the manifest to the originating submission, and a manifestUrl on output and error items linking them back to the Data Provider's submitted manifests."
* ^status = #draft
* ^jurisdiction = $m49.htm#001 "World"

* submissionId 1..1 string "Submission Identifier" "Identifier for the submission this status manifest relates to, matching the submissionId provided by the Data Provider in the $bulk-submit kick-off request."

* output.manifestUrl 0..1 url "Source Manifest URL" "URL of the manifest submitted by the Data Provider that the resources in this output file relate to. A single manifestUrl may be referenced from multiple items in the output section."

* error.manifestUrl 1..1 url "Source Manifest URL" "URL of the manifest submitted by the Data Provider where the issues described in this error file occurred. Each item in the error section SHALL include this element. A single manifestUrl may be referenced from multiple items in the error section."
