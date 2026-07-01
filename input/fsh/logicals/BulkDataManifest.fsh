Logical: BulkDataManifest
Parent: Element
Id: BulkDataManifest
Title: "Bulk Data Manifest"
Description: "Logical model describing a standard format to provide links to FHIR Bulk Data files and related metadata."
* ^status = #active
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 5
* ^jurisdiction = $m49.htm#001 "World"

* transactionTime 1..1 instant "Timestamp for the data included in this manifest" "Indicates the Data Provider's time when the query is run or files were generated. The bulk data files referenced in this manifest SHOULD NOT include any resources modified after this instant, and SHALL include any matching resources modified up to and including this instant."
* requiresAccessToken 1..1 boolean "Token required to retrieve bulk data files" "Indicates whether downloading the files referenced in this manifest requires the same authorization mechanism as the operation that resulted in the manifest. Value SHALL be true if both the Data Provider's file server and the Data Provider's FHIR API server control access using OAuth 2.0 bearer tokens. Value MAY be false for file servers that use access-control schemes other than OAuth 2.0, such as downloads from Amazon S3 bucket URLs or verifiable file servers within an organization's firewall."

* outputFormat 0..1 string "MIME type of the referenced bulk data files" "MIME type of the referenced bulk data output files. Defaults to application/fhir+ndjson when omitted. Corresponds to the _outputFormat parameter in a Bulk Export operation."
* outputOrganizedBy 0..1 string "Resource type used to organize output files" "When resources in the output files are organized by instances of a resource type, that resource type is specified here. When each output file contains a single resource type, this element SHALL be omitted and an individual type element SHALL be included for each file in the output array."
* outputOrganizedByDetail 0..1 string "Output Organized By Detail" "Narrative text providing detail on the organizing resource listed in outputOrganizedBy. SHALL NOT be populated in the absence of the outputOrganizedBy element."

* output 0..* BackboneElement "Output Files" "An array of file items with one entry for each generated file."
  * type 0..1 string "FHIR Resource Type" "The FHIR resource type contained in the file. When the manifest does not include an outputOrganizedBy value, this element SHALL be populated. When the manifest includes the outputOrganizedBy element, this element SHALL NOT be populated."
  * url 1..1 url "File URL" "The absolute path to the file. The format of the file SHOULD reflect that requested in the _outputFormat parameter of the initial kick-off request and the outputFormat element in this manifest."
  * continuesInFile 0..1 url "Continuation File URL" "URL of the next output file when resources for an organizing resource span multiple files."
  * count 0..1 integer "Resource Count" "The number of resources in the file."
  * fileSize 0..1 integer "File Size" "The size of the file in bytes. This provides Data Consumers with information about the storage and processing requirements for downloading and parsing the file."

* deleted 0..* BackboneElement "Deleted Resource Files" "References to files containing pointers to deleted resources in the form of FHIR Transaction Bundles. Each line in the output files SHALL contain a FHIR Bundle with a type of transaction which SHALL contain one or more entry items that reflect a deleted resource. In each entry, the request.url and request.method elements SHALL be populated and request.method SHALL be set to DELETE."
  * url 1..1 url "File URL" "The absolute path to the file."
  * count 0..1 integer "Resource Count" "The number of resources in the file."
  * fileSize 0..1 integer "File Size" "The size of the file in bytes. This provides Data Consumers with information about the storage and processing requirements for downloading and parsing the file."

* outcome 0..* BackboneElement "Outcome Files" "Files containing OperationOutcome resources. Error, success, warning, information and other messages related to the operation SHOULD be included here (not in output)."
  * url 1..1 url "File URL" "The absolute path to the file."
  * count 0..1 integer "Resource Count" "The number of resources in the file."
  * fileSize 0..1 integer "File Size" "The size of the file in bytes. This provides Data Consumers with information about the storage and processing requirements for downloading and parsing the file."
  * countSeverity 0..* BackboneElement "Count by severity" "Count of OperationOutcome resources grouped by severity level."
    * code 1..1 code "Severity" "Severity level from OperationOutcome.issue.severity (fatal, error, warning, information, success)"
    * code from http://hl7.org/fhir/ValueSet/issue-severity (required)
    * count 1..1 integer "Count" "The number of OperationOutcome resources in the file with this severity level."

* link 0..* BackboneElement "Paging links" "Link to related manifest."
  * obeys bdm-link-relation-next
  * relation 1..1 string "Relation" "The relationship type. Value SHALL be 'next', indicating the URL points to the location of another manifest."
  * url 1..1 url "Link URL" "URL pointing to the location of another manifest. All fields in the linked manifest SHALL be populated with the same values as this manifest, apart from the contents of output, deleted, outcome, and link."

Invariant: bdm-link-relation-next
Description: "Manifest links SHALL use a relation value of 'next'."
Severity: #error
Expression: "relation = 'next'"
