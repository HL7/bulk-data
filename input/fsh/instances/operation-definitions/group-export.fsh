Instance: group-export
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export"
* version = "2.0.0"
* name = "GroupLevelExport"
* title = "FHIR Bulk Data Group Level Export"
* status = #active
* kind = #operation
* date = "2020-07-29"
* jurisdiction = $m49.htm#001 "World"
* description = "FHIR Operation to obtain a detailed set of FHIR resources of diverse resource types pertaining to all members of the specified [Group](https://www.hl7.org/fhir/group.html). The FHIR server SHALL support invocation of this operation using the [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html)"
* code = #export
* resource = #Group
* system = false
* type = false
* instance = true
* insert ExportParam_outputFormat
* parameter[+]
  * name = #_since
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is required for a server, optional for a client.

    Resources will be included in the response if their state has changed after the supplied time (e.g., if `Resource.meta.lastUpdated` is later than the supplied `_since` time). In the case of a [Group level export](export.html#endpoint---group-of-patients), the server MAY return additional resources modified prior to the supplied time if the resources belong to the patient compartment of a patient added to the Group after the supplied time (this behavior SHOULD be clearly documented by the server). The server MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the server does not maintain a last updated time, the server MAY include these resources in a response irrespective of the `_since` value supplied by a client.
    """
  * type = #instant
* insert ExportParam_until
* insert ExportParam_type
* insert ExportParam_elements
* insert ExportParam_patient
* insert ExportParam_includeAssociatedData
* insert ExportParam_typeFilter
* insert ExportParam_organizeOutputBy
* insert ExportParam_allowPartialManifests
