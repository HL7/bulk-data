Logical: BulkDataManifest
Parent: AsyncManifest
Id: BulkDataManifest
Title: "Bulk Data Manifest"
Description: "Logical model describing a standard format to provide links to FHIR Bulk Data files and related metadata."
* ^status = #active
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 5
* ^jurisdiction = $m49.htm#001 "World"

* transactionTime ^definition = "Indicates the Data Provider's time when the query is run or files were generated. The bulk data files referenced in this manifest SHOULD NOT include any resources modified after this instant, and SHALL include any matching resources modified up to and including this instant."
* requiresAccessToken ^definition = "Indicates whether downloading the files referenced in this manifest requires the same authorization mechanism as the operation that resulted in the manifest. Value SHALL be true if both the Data Provider's file server and the Data Provider's FHIR API server control access using OAuth 2.0 bearer tokens. Value MAY be false for file servers that use access-control schemes other than OAuth 2.0, such as downloads from Amazon S3 bucket URLs or verifiable file servers within an organization's firewall."
* outputFormat ^definition = "MIME type of the referenced bulk data output files. Defaults to application/fhir+ndjson when omitted. Corresponds to the _outputFormat parameter in a Bulk Export operation."
* output.url ^definition = "The absolute path to the file. The format of the file SHOULD reflect that requested in the _outputFormat parameter of the initial kick-off request and the outputFormat element in this manifest."
* deleted ^definition = "References to files identifying resources that the Data Provider is requesting the Data Consumer to remove from its local dataset. See [Deleted Resources](export.html#deleted-resources)."
