Instance: patient-export
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/patient-export"
* version = "4.0.0"
* name = "PatientLevelExport"
* title = "FHIR Bulk Data Patient Level Export"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 5
* kind = #operation
* affectsState = true
* date = "2021-07-29"
* jurisdiction = $m49.htm#001 "World"
* description = "FHIR Operation through which an authenticated and authorized Data Consumer requests a detailed set of FHIR resources of diverse resource types pertaining to all patients from a Data Provider. The Data Provider's FHIR Resource Server SHALL support invocation of this operation using HTTP POST and the [FHIR Asynchronous Bulk Interaction Pattern](async.html)."
* code = #export
* resource = #Patient
* system = false
* type = true
* instance = false
* insert ExportParam_outputFormat
* insert ExportParam_since
* insert ExportParam_until
* insert ExportParam_type
* insert ExportParam_elements
* insert ExportParam_patient
* insert ExportParam_includeAssociatedData
* insert ExportParam_typeFilter
* insert ExportParam_organizeOutputBy
* insert ExportParam_allowPartialManifests
