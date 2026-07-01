Instance: BulkDataManifestByTypeExample
InstanceOf: BulkDataManifest
Title: "Bulk Data Manifest Example By Resource Type"
Description: "Example Bulk Data output manifest when organizeOutputBy is not populated."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = true
* output[0].type = "Patient"
* output[0].url = "https://example.org/output/patient_file_1.ndjson"
* output[1].type = "Observation"
* output[1].url = "https://example.org/output/observation_file_1.ndjson"
* output[2].type = "Observation"
* output[2].url = "https://example.org/output/observation_file_2.ndjson"
* deleted[0].url = "https://example.org/output/del_file_1.ndjson"
* outcome[0].url = "https://example.org/output/err_file_1.ndjson"
* extension[0].url = "http://example.org/fhir/StructureDefinition/includes-telehealth-patients"
* extension[0].valueBoolean = true

Instance: BulkDataManifestOrganizedByPatientExample
InstanceOf: BulkDataManifest
Title: "Bulk Data Manifest Example Organized By Patient"
Description: "Example Bulk Data output manifest when organizeOutputBy is Patient and allowPartialManifests is true."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = true
* outputOrganizedBy = "Patient"
* output[0].url = "https://example.org/output/file_1.ndjson"
* output[1].url = "https://example.org/output/file_2.ndjson"
* output[1].continuesInFile = "https://example.org/output/file_3.ndjson"
* output[2].url = "https://example.org/output/file_3.ndjson"
* deleted[0].url = "https://example.org/output/del_file_1.ndjson"
* outcome[0].url = "https://example.org/output/err_file_1.ndjson"
* extension[0].url = "http://example.org/fhir/StructureDefinition/includes-telehealth-patients"
* extension[0].valueBoolean = true
* link[0].relation = "next"
* link[0].url = "https://example.org/output/manifest-2.json"

Instance: BulkDataManifestMinimalExample
InstanceOf: BulkDataManifest
Title: "Minimal Bulk Data Manifest"
Description: "Example Bulk Data output manifest when organizeOutputBy is Patient and allowPartialManifests is true."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = true
* output[0].type = "Patient"
* output[0].url = "https://example.org/output/patient_file_1.ndjson"
