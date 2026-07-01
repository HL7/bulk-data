Instance: BulkPublishManifestMinimalExample
InstanceOf: BulkPublishManifest
Title: "Minimal Bulk Publish Manifest"
Description: "Example minimal, non-incremental Bulk Publish manifest."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = false
* output[0].type = "Organization"
* output[0].url = "https://example.com/output/organization_1.ndjson"
* output[1].type = "Organization"
* output[1].url = "https://example.com/output/organization_2.ndjson"

Instance: BulkPublishManifestPagedExample
InstanceOf: BulkPublishManifest
Title: "Paged Bulk Publish Manifest"
Description: "Example first page of a Bulk Publish manifest divided into ordinary manifest pages."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = false
* output[0].type = "Organization"
* output[0].url = "https://example.com/output/organization_1.ndjson"
* link[0].relation = "next"
* link[0].url = "https://example.com/manifests/provider-directory-page-2.json"

Instance: BulkPublishManifestPagedNextPageExample
InstanceOf: BulkPublishManifest
Title: "Paged Bulk Publish Manifest Next Page"
Description: "Example second page of a Bulk Publish manifest divided into ordinary manifest pages."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* requiresAccessToken = false
* output[0].type = "Practitioner"
* output[0].url = "https://example.com/output/practitioner_1.ndjson"
* output[1].type = "PractitionerRole"
* output[1].url = "https://example.com/output/practitioner_role_1.ndjson"

Instance: BulkPublishManifestPendingRootExample
InstanceOf: BulkPublishManifest
Title: "Bulk Publish Manifest With Pending Update Chain"
Description: "Example root Bulk Publish manifest that links to a pending update-chain page."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* updateCadence = "P1D"
* requiresAccessToken = false
* output[0].type = "Organization"
* output[0].url = "https://example.com/output/organization_1.ndjson"
* link[0].relation = "next"
* link[0].url = "https://example.com/manifests/provider-directory-update-1.json"

Instance: BulkPublishManifestPendingStubExample
InstanceOf: BulkPublishManifest
Title: "Pending Bulk Publish Manifest Page"
Description: "Example Bulk Publish manifest page that advertises a pending incremental update."
Usage: #example
* transactionTime = "2021-01-01T00:00:00Z"
* updateCadence = "P1D"
* requiresAccessToken = false
* link[0].relation = "next"
* link[0].url = "#pending"

Instance: BulkPublishManifestIncrementalUpdateExample
InstanceOf: BulkPublishManifest
Title: "Bulk Publish Incremental Update Manifest"
Description: "Example Bulk Publish manifest page containing an incremental update and a pending next link."
Usage: #example
* updateCadence = "P1D"
* transactionTime = "2021-01-02T00:00:00Z"
* requiresAccessToken = false
* output[0].type = "Organization"
* output[0].url = "https://example.com/output/organization_2.ndjson"
* deleted[0].url = "https://example.com/output/deleted_org_1.ndjson"
* link[0].relation = "next"
* link[0].url = "#pending"
