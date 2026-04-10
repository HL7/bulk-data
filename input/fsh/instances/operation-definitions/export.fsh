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
* description = "FHIR Operation through which an authenticated and authorized Data Consumer may request bulk FHIR data from a Data Provider, whether or not the data is associated with a patient. This supports use cases like backing up a Data Provider's FHIR server, or exporting terminology data by restricting the resources returned using the _type parameter. The Data Provider's FHIR Resource Server SHALL support invocation of this operation using the [FHIR Asynchronous Bulk Interaction Pattern](async.html)"
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
    Support is optional for a Data Provider, optional for a Data Consumer.

    The response SHALL be filtered to only include resources of the specified resource types(s).

    If this parameter is omitted, the Data Provider SHALL return all supported resources within the scope of the Data Consumer's authorization, though implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/).

    A Data Provider that is unable to support `_type` SHOULD return an error and FHIR `OperationOutcome` resource so the Data Consumer can re-submit a request omitting the `_type` parameter. If the Data Consumer explicitly asks for export of resources that the Data Provider does not support, or asks for only resource types that are outside the Patient Compartment, the Data Provider SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request. When a `Prefer: handling=lenient` header is included in the request, the Data Provider MAY process the request instead of returning an error.

    For example `_type=Observation` could be used to filter a given export response to return only FHIR `Observation` resources.
    """
  * type = #string
* insert ExportParam_elements
* insert ExportParam_includeAssociatedData
* insert ExportParam_typeFilter
* insert ExportParam_organizeOutputBy
* insert ExportParam_allowPartialManifests
