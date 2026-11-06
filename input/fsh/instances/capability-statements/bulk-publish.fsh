Instance: BulkPublishCapabilityStatement
InstanceOf: CapabilityStatement
Usage: #definition
* id = "bulk-publish"
* url = "http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-publish"
* version = "4.0.0"
* name = "BulkPublishCapabilityStatement"
* title = "Bulk Publish Capability Statement"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 2
* experimental = false
* date = "2026-11-06"
* description = "The expected capabilities of a Data Provider actor that publishes Bulk Data files for retrieval by Data Consumers using the `$bulk-publish` operation. Systems implementing this capability statement SHOULD meet the Bulk Publish requirements set by the Bulk Data Access Implementation Guide."
* jurisdiction = $m49.htm#001 "World"
* kind = #requirements
* fhirVersion = #4.0.1
* format = #application/fhir+json
* implementationGuide = "http://hl7.org/fhir/uv/bulkdata/ImplementationGuide/hl7.fhir.uv.bulkdata"
* rest
  * mode = #server
  * documentation = "This FHIR Operation returns a Bulk Publish manifest with links to Bulk Data files that the Data Provider has published. See [Bulk Publish](publish.html)."
  * operation[+]
    * extension
      * url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
      * valueCode = #SHALL
    * name = "bulk-publish"
    * definition = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish"
    * documentation = "FHIR Operation invoked with an HTTP GET request to retrieve a Bulk Publish manifest."
  * security.description = "Data Providers MAY implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html). Implementations MAY use authorization schemes other than OAuth 2.0, such as mutual TLS or capability URLs."
