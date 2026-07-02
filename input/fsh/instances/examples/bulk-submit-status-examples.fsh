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
