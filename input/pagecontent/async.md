This FHIR Asynchronous Bulk Interaction Pattern, described below, represents a FHIR request and response flow that servers can implement for any [Operation](https://hl7.org/fhir/operations.html) or [Defined Interaction](https://hl7.org/fhir/http.html) that needs to return a large dataset.

The [Bulk Export Operation](export.html) builds on this pattern.

Use cases that return small amounts of data but may take a lot of time to process may prefer to use the related [Asynchronous Interaction Request Pattern](https://hl7.org/fhir/async-bundle.html).

This pattern is described in the FHIR R4 and FHIR R5 versions of the [FHIR specification](https://hl7.org/fhir), and has been moved into this Implementation Guide going forward.

### FHIR Asynchronous Bulk Interaction Request Flow

#### Kick-off Request

The request will support the HTTP methods, URLs, headers, and other parameters that normally apply to the interaction being invoked. Servers SHALL also support the `Prefer` header described below, and SHOULD support the `Accept` header and `_outputFormat` parameter described below.

##### Headers

- `Accept` (string)

  Specifies the format of the optional FHIR `OperationOutcome` resource response to the kick-off request. A client SHOULD provide this header. A server may support any subset of the [Serialization Format Representations](https://hl7.org/fhir/resource-formats.html#wire). If omitted, the server MAY return an error or MAY process the request and return a format selected by the server.

- `Prefer` (string, required)

  Specifies whether the response is immediate or asynchronous. Setting this to <a href="https://datatracker.ietf.org/doc/html/rfc7240#section-4.1"><code>respond-async</code></a> triggers this asynchronous bulk pattern.

##### Parameters

- `_outputFormat` (string, optional, defaults to `application/fhir+ndjson`)

  The format for the generated bulk data files. Currently, [NDJSON](http://ndjson.org/) SHALL be supported, though servers MAY also support other output formats. Servers SHALL support the full content type of `application/fhir+ndjson` as well as abbreviated representations including `application/ndjson` and `ndjson`.

  For request types where the server supports either the Asynchronous Bulk Interaction Pattern or the [Asynchronous Interaction Request Pattern](https://hl7.org/fhir/async-bundle.html), requests that include the `_outputFormat` parameter SHALL trigger the Asynchronous Bulk Interaction Pattern.

- `_minimumFileSize` (number, optional)

  Specifies the minimum size in bytes for generated NDJSON files. The value SHALL be a positive integer. If a server supports this parameter, it SHOULD construct files that meet or exceed this size unless doing so would violate the `_maximumFileSize` constraint.

- `_maximumFileSize` (number, optional)

  Specifies the maximum size in bytes for generated NDJSON files. The value SHALL be a positive integer and SHALL be greater than `_minimumFileSize` if both are specified. If a server supports this parameter, it SHALL construct files that do not exceed this size. The server MAY use a lower internal maximum.

Implementation notes:

- If neither `_minimumFileSize` nor `_maximumFileSize` is specified, servers use their default file size behavior.
- Servers MAY deviate from the specified `_minimumFileSize` and `_maximumFileSize` when necessary, for example for the last file in a sequence or when a resource is larger than `_maximumFileSize`.
- Servers SHOULD document any fixed file size bounds they implement.

##### Response - Success

- HTTP Status Code of `202 Accepted`
- `Content-Location` header with the absolute URL of an endpoint for subsequent status requests
- Optionally, a FHIR `OperationOutcome` resource in the body

##### Response - Error

- HTTP Status Code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource

---
{% include async-delete-request.md %}

---
{% include async-status-polling-request.md %}

##### Response - Output Manifest

{% include async-output-manifest.md %}

---
{% include async-output-file-request.md %}
{% include async-attachments.md %}
