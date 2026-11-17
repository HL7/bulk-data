Logical: AsyncManifest
Parent: Element
Id: AsyncManifest
Title: "Asynchronous Bulk Interaction Manifest"
Description: "Abstract logical model describing the common structure of a manifest that provides links to FHIR Bulk Data files and related metadata. Operations that use the FHIR Asynchronous Bulk Interaction Pattern define manifests that extend it, such as the Bulk Data Manifest used by Bulk Export."
* ^status = #active
* ^abstract = true
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 5
* ^jurisdiction = $m49.htm#001 "World"

* manifestType 0..1 canonical "Logical model that defines this manifest" "Canonical reference to the logical model that defines the structure of this manifest. When populated, the canonical SHALL include the version of the logical model, e.g., `http://hl7.org/fhir/uv/bulkdata/StructureDefinition/BulkDataManifest|4.0.0`. This element will be mandatory in a future release of this IG."
* transactionTime 1..1 instant "Timestamp for the data included in this manifest" "Indicates the server's time when the files referenced in this manifest were generated. The files referenced in this manifest SHOULD NOT include any resources modified after this instant, and SHALL include all resources within the scope of the request modified up to and including this instant."
* requiresAccessToken 1..1 boolean "Token required to retrieve bulk data files" "Indicates whether downloading the files referenced in this manifest requires the same authorization mechanism as the operation that produced the manifest. Value SHALL be true if both the file server and the server that produced the manifest control access using OAuth 2.0 bearer tokens. Value MAY be false for file servers that use access-control schemes other than OAuth 2.0, such as downloads from Amazon S3 bucket URLs or verifiable file servers within an organization's firewall."

* outputFormat 0..1 string "MIME type of the referenced bulk data files" "MIME type of the referenced output files. Defaults to application/fhir+ndjson when omitted. Corresponds to the output format requested from the operation that produced the manifest, when that operation supports one."
* outputOrganizedBy 0..1 uri "Resource type used to organize output files" "When resources in the output files are organized by instances of a resource type, that resource type is specified here. The value is a resource type name (e.g., `Patient`), even when the request that produced the manifest used an absolute URI. When each output file contains a single resource type, this element SHALL be omitted and an individual type element SHALL be included for each file in the output array."
* outputOrganizedByDetail 0..1 string "Output Organized By Detail" "Narrative text providing detail on the organizing resource listed in outputOrganizedBy. SHALL NOT be populated in the absence of the outputOrganizedBy element."

* output 0..* BackboneElement "Output Files" "An array of file items with one entry for each generated file."
  * type 0..1 string "FHIR Resource Type" "The FHIR resource type contained in the file. When the manifest does not include an outputOrganizedBy value, this element SHALL be populated. When the manifest includes the outputOrganizedBy element, this element SHALL NOT be populated."
  * url 1..1 url "File URL" "The absolute path to the file. The format of the file SHOULD reflect the outputFormat element in this manifest."
  * continuesInFile 0..1 url "Continuation File URL" "URL of the next output file when resources for an organizing resource span multiple files."
  * count 0..1 integer "Resource Count" "The number of resources in the file."
  * fileSize 0..1 integer "File Size" "The size of the file in bytes. This provides the party retrieving the file with information about the storage and processing requirements for downloading and parsing the file."

* deleted 0..* BackboneElement "Deleted Resource Files" "References to files identifying resources to be removed. The operation that produced the manifest defines which party is asked to remove them."
  * url 1..1 url "File URL" "The absolute path to the file."
  * count 0..1 integer "Resource Count" "The number of resources in the file."
  * fileSize 0..1 integer "File Size" "The size of the file in bytes. This provides the party retrieving the file with information about the storage and processing requirements for downloading and parsing the file."

* outcome 0..* BackboneElement "Outcome Files" "Files containing OperationOutcome resources. Error, success, warning, information and other messages related to the operation SHOULD be included here (not in output)."
  * url 1..1 url "File URL" "The absolute path to the file."
  * count 0..1 integer "Resource Count" "The number of resources in the file."
  * fileSize 0..1 integer "File Size" "The size of the file in bytes. This provides the party retrieving the file with information about the storage and processing requirements for downloading and parsing the file."
  * countSeverity 0..* BackboneElement "Count by severity" "Count of `OperationOutcome.issue` entries in the file, grouped by issue severity."
    * code 1..1 code "Severity" "Severity level from OperationOutcome.issue.severity (fatal, error, warning, information, success)"
    * code from http://hl7.org/fhir/ValueSet/issue-severity (required)
    * count 1..1 integer "Count" "The number of `OperationOutcome.issue` entries in the file with this severity."

* link 0..1 BackboneElement "Paging links" "Link to related manifest."
  * obeys bdm-link-relation-next
  * relation 1..1 string "Relation" "The relationship type. Value SHALL be 'next', indicating the URL points to the location of another manifest."
  * url 1..1 url "Link URL" "URL pointing to the location of another manifest. All fields in the linked manifest SHALL be populated with the same values as this manifest, apart from the contents of output, deleted, outcome, and link."

Invariant: bdm-link-relation-next
Description: "Manifest links SHALL use a relation value of 'next'."
Severity: #error
Expression: "relation = 'next'"
