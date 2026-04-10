The output manifest is a JSON object providing metadata and links to the generated Bulk Data files. The files SHALL be accessible to the client at the URLs advertised. These URLs MAY be served by file servers other than the server that accepted the asynchronous request.

{% include export-manifest-fields.md %}

Implementation notes:

- For `transactionTime`, to properly meet the inclusion constraints above, a server might need to wait for any pending transactions to resolve in its database before starting the asynchronous operation process.
- Error, warning, and information messages related to the asynchronous operation SHOULD be included in `error` and not in `output`. If there are no relevant messages, the server SHOULD return an empty array. If the request contained invalid or unsupported parameters along with a `Prefer: handling=lenient` header and the server processed the request, the server SHOULD include a FHIR `OperationOutcome` resource for each of these parameters.
- When a timestamp parameter such as `_since` is supported by the request type and supplied in the kick-off request, the `deleted` array SHOULD be populated with files containing FHIR transaction Bundles for resources that match the kick-off request criteria but were deleted after the supplied time. If no resources have been deleted, if no such timestamp was supplied, or if the server has other reasons to avoid exposing these data, the server MAY omit this key or return an empty array. Resources that appear in `deleted` SHALL NOT also appear in `output`.

Example manifest:
<div class="language-json">
{% include Binary-BulkDataManifestMinimalExample-html.xhtml %}
</div>

[View Example](Binary-BulkDataManifestMinimalExample.html)
