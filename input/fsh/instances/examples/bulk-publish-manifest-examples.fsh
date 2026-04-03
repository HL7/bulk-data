Instance: BulkPublishManifestMinimalExample
InstanceOf: BulkPublishManifest
Title: "Minimal Bulk Publish Manifest"
Description: "Example minimal, non-incremental Bulk Publish manifest."
Usage: #example
* manifestType = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish"
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = false
* output[0].type = "Organization"
* output[0].url = "https://example.com/output/organization_1.ndjson"
* output[1].type = "Organization"
* output[1].url = "https://example.com/output/organization_2.ndjson"

Instance: BulkPublishManifestEpochStartExample
InstanceOf: BulkPublishManifest
Title: "Bulk Publish Manifest at Epoch Start"
Description: "Example Bulk Publish manifest at the epoch start."
Usage: #example
* manifestType = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish"
* epochStartTime = "2021-01-01T00:00:00Z"
* updateCadence = "PT1H"
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = false
* output[0].type = "Organization"
* output[0].url = "https://example.com/output/organization_1.ndjson"
* output[1].type = "Organization"
* output[1].url = "https://example.com/output/organization_2.ndjson"

Instance: BulkPublishManifestIncrementalUpdateExample
InstanceOf: BulkPublishManifest
Title: "Bulk Publish Manifest After First Incremental Update"
Description: "Example Bulk Publish manifest after the first incremental update."
Usage: #example
* manifestType = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish"
* epochStartTime = "2021-01-01T00:00:00Z"
* updateCadence = "PT1H"
* transactionTime = "2021-01-01T01:00:00Z"
* requiresAccessToken = false
* output[0].type = "Organization"
* output[0].url = "https://example.com/output/organization_1.ndjson"
* output[1].type = "Organization"
* output[1].url = "https://example.com/output/organization_2.ndjson"
* output[2].type = "Organization"
* output[2].url = "https://example.com/output/organization_3.ndjson"
* deleted[0].url = "https://example.com/output/deleted_org_1.ndjson"
