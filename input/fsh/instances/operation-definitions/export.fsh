Instance: export
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/export"
* version = "2.0.0"
* name = "BulkDataExport"
* title = "FHIR Bulk Data System Level Export"
* status = #active
* kind = #operation
* date = "2021-07-29"
* jurisdiction = $m49.htm#001 "World"
* description = "FHIR Operation to export data from a FHIR server whether or not it is associated with a patient. This supports use cases like backing up a server, or exporting terminology data by restricting the resources returned using the _type parameter. The FHIR server SHALL support invocation of this operation using the [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html)"
* code = #export
* system = true
* type = false
* instance = false
* insert ExportParam_outputFormat
* insert ExportParam_since
* insert ExportParam_until
* parameter[+]
  * name = #_type
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Support is optional for a server, optional for a client.

    The response SHALL be filtered to only include resources of the specified resource types(s).

    If this parameter is omitted, the server SHALL return all supported resources within the scope of the client authorization, though implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/).

    A server that is unable to support `_type` SHOULD return an error and FHIR `OperationOutcome` resource so the client can re-submit a request omitting the `_type` parameter. If the client explicitly asks for export of resources that the Bulk Data server doesn't support, or asks for only resource types that are outside the Patient Compartment, the server SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request. When a `Prefer: handling=lenient` header is included in the request, the server MAY process the request instead of returning an error.

    For example `_type=Observation` could be used to filter a given export response to return only FHIR `Observation` resources.
    """
  * type = #string
* insert ExportParam_elements
* insert ExportParam_includeAssociatedData
* insert ExportParam_typeFilter
* insert ExportParam_organizeOutputBy
* insert ExportParam_allowPartialManifests
