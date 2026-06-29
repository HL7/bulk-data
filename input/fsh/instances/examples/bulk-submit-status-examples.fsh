Instance: BulkSubmitStatusManifestExample
InstanceOf: BulkSubmitStatusManifest
Title: "Bulk Submit Status Manifest Example"
Description: "Example bulk submit status manifest returned by a Data Consumer."
Usage: #example
* submissionId = "a15eea1f-1605-4303-989f-542d3a7962d8"
* transactionTime = "2025-01-01T00:00:00Z"
* requiresAccessToken = true
* error[0].url = "http://example.org/output/import_errors_1.ndjson"
* error[0].manifestUrl = "http://example.org/manifests/3556d214-c6e2-42e6-a7f7-89690f7a40bb_1"
* error[0].countSeverity[0].code = #information
* error[0].countSeverity[0].count = 0
* error[0].countSeverity[1].code = #error
* error[0].countSeverity[1].count = 100
* error[1].url = "http://example.org/output/validation_errors_2.ndjson"
* error[1].manifestUrl = "https//example.org/manifests/3556d214-c6e2-42e6-a7f7-89690f7a40bb_2"
* error[1].countSeverity[0].code = #information
* error[1].countSeverity[0].count = 98
* error[1].countSeverity[1].code = #error
* error[1].countSeverity[1].count = 2

Instance: SubmitStatusResourceOperationOutcomeExample
InstanceOf: OperationOutcome
Title: "Bulk Submit Resource-Level Status OperationOutcome Example"
Description: "Example OperationOutcome describing resource-level validation failures for a bulk submit."
Usage: #example
* id = "submit-status-resource-operationoutcome-example"
* extension[+].url = "http://hl7.org/fhir/StructureDefinition/operationoutcome-sourceResource"
* extension[=].valueReference.reference = "http://example.org/fhir/Patient/pt-1"
* extension[+].url = "http://hl7.org/fhir/StructureDefinition/operationoutcome-sourceResource"
* extension[=].valueReference.reference = "http://example.org/fhir/Patient/pt-2"
* issue[0].severity = #error
* issue[0].code = #structure
* issue[0].details.text = "Error parsing resource json (Unknown Content 'label')"
* issue[0].location[0] = "/f:Patient/f:identifier"
* issue[0].expression[0] = "Patient.identifier"

Instance: SubmitStatusManifestOperationOutcomeExample
InstanceOf: OperationOutcome
Title: "Bulk Submit Status Manifest-Level OperationOutcome Example"
Description: "Example OperationOutcome describing manifest-level submit status."
Usage: #example
* id = "submit-status-manifest-operationoutcome-example"
* issue[0].severity = #information
* issue[0].code = #informational
* issue[0].details.text = "Manifest http://example.org/manifests/3556d214-c6e2-42e6-a7f7-89690f7a40bb_2 successfully imported."
