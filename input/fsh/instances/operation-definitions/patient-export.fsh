Instance: patient-export
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/patient-export"
* version = "2.0.0"
* name = "PatientLevelExport"
* title = "FHIR Bulk Data Patient Level Export"
* status = #active
* kind = #operation
* date = "2021-07-29"
* jurisdiction = $m49.htm#001 "World"
* description = "FHIR Operation through which an authenticated and authorized Data Consumer may request a detailed set of FHIR resources of diverse resource types pertaining to all patients from a Data Provider. The Data Provider's FHIR Resource Server SHALL support invocation of this operation using the [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html)"
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
