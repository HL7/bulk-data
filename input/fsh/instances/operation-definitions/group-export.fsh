Instance: group-export
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export"
* version = "4.0.0"
* name = "GroupLevelExport"
* title = "FHIR Bulk Data Group Level Export"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 5
* kind = #operation
* date = "2020-07-29"
* jurisdiction = $m49.htm#001 "World"
* description = "FHIR Operation through which an authenticated and authorized Data Consumer requests a detailed set of FHIR resources of diverse resource types pertaining to all members of the specified [Group](https://www.hl7.org/fhir/group.html) from a Data Provider. The Data Provider's FHIR Resource Server SHALL support invocation of this operation using the [FHIR Asynchronous Bulk Interaction Pattern](async.html)"
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
    Support is required for a Data Provider, optional for a Data Consumer.

    Resources will be included in the response if their state has changed after the supplied time (e.g., if `Resource.meta.lastUpdated` is later than the supplied `_since` time). In the case of a [Group level export](export.html#endpoint---group-of-patients), the Data Provider MAY return additional resources modified prior to the supplied time if the resources belong to the patient compartment of a patient added to the Group after the supplied time (this behavior SHOULD be clearly documented by the Data Provider). The Data Provider MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the Data Provider does not maintain a last updated time, the Data Provider MAY include these resources in a response irrespective of the `_since` value supplied by a Data Consumer.
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
