Instance: BulkSubmitCapabilityStatement
InstanceOf: CapabilityStatement
Usage: #definition
* id = "bulk-submit"
* url = "http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-submit"
* version = "4.0.0"
* name = "BulkSubmitCapabilityStatement"
* title = "Bulk Submit Capability Statement"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 2
* experimental = false
* date = "2026-11-06"
* description = "The expected capabilities of a Data Consumer actor that accepts Bulk Submit requests. In Bulk Submit, the Data Consumer hosts the Submission Server, and the Data Provider invokes the `$bulk-submit` and `$bulk-submit-status` operations to submit data and to track the processing of a submission. Systems implementing this capability statement SHOULD meet the Bulk Submit requirements set by the Bulk Data Access Implementation Guide."
* jurisdiction = $m49.htm#001 "World"
* kind = #requirements
* fhirVersion = #4.0.1
* format = #application/fhir+json
* implementationGuide = "http://hl7.org/fhir/uv/bulkdata/ImplementationGuide/hl7.fhir.uv.bulkdata"
* rest
  * mode = #server
  * documentation = "These FHIR Operations are hosted by the Data Consumer and invoked by the Data Provider to submit Bulk Data files and to retrieve the status of a submission. See [Bulk Submit](submit.html)."
  * operation[+]
    * extension
      * url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
      * valueCode = #SHALL
    * name = "bulk-submit"
    * definition = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-submit"
    * documentation = "FHIR Operation invoked by a Data Provider to submit a manifest of Bulk Data files to the Data Consumer, or to replace or cancel a submission."
  * operation[+]
    * extension
      * url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
      * valueCode = #SHALL
    * name = "bulk-submit-status"
    * definition = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-submit-status"
    * documentation = "FHIR Operation invoked by a Data Provider, using the [FHIR Asynchronous Bulk Interaction Pattern](async.html), to retrieve a Bulk Submit Status manifest describing the processing of a submission."
  * security.description = "Data Consumers SHOULD implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html). Implementations MAY include non-RESTful services that use authorization schemes other than OAuth 2.0, such as mutual TLS or signed URLs."
