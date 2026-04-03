Instance: DeletedResourceTransactionBundleExample
InstanceOf: Bundle
Title: "Deleted Resource Transaction Bundle Example"
Description: "Example transaction bundle representing a deleted resource in a bulk data deleted output file."
Usage: #example
* id = "deleted-resource-transaction-bundle-example"
* meta.lastUpdated = "2020-04-27T02:56:00Z"
* type = #transaction
* entry[0].request.method = #DELETE
* entry[0].request.url = "Patient/123"
