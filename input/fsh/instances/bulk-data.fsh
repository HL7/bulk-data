Instance: bulk-data
InstanceOf: CapabilityStatement
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data"
* version = "2.0.0"
* name = "BulkDataIGCapabilityStatement"
* title = "FHIR Bulk Data Access Implementation Guide"
* status = #active
* experimental = false
* date = "2021-07-29"
* description = "The expected capabilities of a Bulk Data Provider actor (e.g., EHR systems, data warehouses, and other clinical and administrative systems that aim to interoperate by sharing large FHIR datasets) which is responsible for providing responses to the queries submitted by a FHIR Bulk Data Client actor. Systems implementing this capability statement should meet the requirements set by the Bulk Data Access Implementation Guide. A FHIR Bulk Data Client has the option of choosing from this list to access necessary data based on use cases and other contextual requirements."
* jurisdiction = $m49.htm#001 "World"
* kind = #requirements
* instantiates = "http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data"
* fhirVersion = #4.0.1
* format = #json
* implementationGuide = "http://hl7.org/fhir/uv/bulkdata/ImplementationGuide/hl7.fhir.uv.bulkdata"
* rest
  * mode = #server
  * documentation = "These FHIR Operations initiate the generation of data to which the client is authorized -- whether that be all patients, a subset (defined group) of patients, or all available data contained in a FHIR server.\n\nThe FHIR server SHALL limit the data returned to only those FHIR resources for which the client is authorized.\n\nThe FHIR server SHALL support invocation of this operation using the [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html). Servers SHALL support GET requests and MAY support POST requests that supply parameters using the FHIR [Parameters Resource](https://www.hl7.org/fhir/parameters.html)."
  * resource[0]
    * type = #Group
    * operation
      * extension
        * url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
        * valueCode = #SHOULD
      * name = "export"
      * definition = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export"
      * documentation = "FHIR Operation to obtain a detailed set of FHIR resources of diverse resource types pertaining to all patients in specified [Group](https://www.hl7.org/fhir/group.html).\n\nIf a FHIR server supports Group-level data export, it SHOULD support reading and searching for `Group` resource. This enables clients to discover available groups based on stable characteristics such as `Group.identifier`.\n\nThe [Patient Compartment](https://www.hl7.org/fhir/compartmentdefinition-patient.html) SHOULD be used as a point of reference for recommended resources to be returned and, where applicable, Patient resources SHOULD be returned. Other resources outside of the patient compartment that are helpful in interpreting the patient data (such as Organization and Practitioner) MAY also be returned."
  * resource[+]
    * type = #Patient
    * operation
      * extension
        * url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
        * valueCode = #SHOULD
      * name = "export"
      * definition = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/patient-export"
      * documentation = "FHIR Operation to obtain a detailed set of FHIR resources of diverse resource types pertaining to all patients.\n\nThe [Patient Compartment](https://www.hl7.org/fhir/compartmentdefinition-patient.html) SHOULD be used as a point of reference for recommended resources to be returned and, where applicable, Patient resources SHOULD be returned. Other resources outside of the patient compartment that are helpful in interpreting the patient data (such as Organization and Practitioner) MAY also be returned."
  * operation
    * extension
      * url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
      * valueCode = #SHOULD
    * name = "export"
    * definition = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/export"
    * documentation = "FHIR Operation to export data from a FHIR server, whether or not it is associated with a patient. This supports use cases like backing up a server, or exporting terminology data by restricting the resources returned using the `_type` parameter."
  * security.description = "Servers SHOULD implement OAuth 2.0 access management in accordance with the [SMART Backend Services: Authorization Guide](authorization.html).  Implementations MAY include non-RESTful services that use authorization schemes other than OAuth 2.0, such as mutual-TLS or signed URLs."