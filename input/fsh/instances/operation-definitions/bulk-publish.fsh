Instance: bulk-publish
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish"
* version = "1.0.0"
* name = "BulkDataPublish"
* title = "FHIR Bulk Data Publish"
* status = #active
* kind = #operation
* date = "2025-01-27"
* jurisdiction = $m49.htm#001 "World"
* description = "FHIR Operation to publish bulk data files for retrieval by Data Consumers. A Data Provider responds to GET requests at a path ending in `/$bulk-publish` by returning a Bulk Data Publish Manifest containing metadata and links to available Bulk Data files. Unlike `$export`, this operation does not initiate on-demand data generation; instead, it provides access to static or periodically updated datasets published by the Data Provider. The Bulk Publish API does not require a FHIR server implementation; many Data Providers may implement it using a simple HTTP server that returns a manifest in response to GET requests."
* code = #bulk-publish
* system = true
* type = false
* instance = false
