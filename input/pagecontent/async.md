{% assign bulk_server_role = "server" %}
{% assign bulk_client_role = "client" %}
The FHIR Asynchronous Bulk Interaction Pattern, described below, is a FHIR request and response flow that servers can implement for any [Operation](https://hl7.org/fhir/operations.html) or [Defined Interaction](https://hl7.org/fhir/http.html) that needs to return a large dataset. This pattern is described in the FHIR R4 and FHIR R5 versions of the [FHIR specification](https://hl7.org/fhir), and has been moved into this Implementation Guide going forward.

The [Bulk Export Operation](export.html) and the [Bulk Submit Status Operation](submit.html#bulk-submit-status-request) in this IG build on this pattern.

Use cases that return small amounts of data but may take a lot of time to process may prefer to use the related [Asynchronous Interaction Request Pattern](https://hl7.org/fhir/async-bundle.html).

### FHIR Asynchronous Bulk Interaction Flow

 <figure>
  {% include async-flow.svg %}
  <figcaption>Overview of the FHIR Asynchronous Bulk Interaction request flow.</figcaption>
</figure>

#### Kick-off Request

The request will support the HTTP methods, URLs, headers, and other parameters that normally apply to the interaction being invoked. Servers SHALL also support the `Prefer` header described below, and SHOULD support the `Accept` header and `_outputFormat` parameter described below.

##### Headers

- `Accept` (string)

  Specifies the format of the optional FHIR `OperationOutcome` resource response to the kick-off request. A client SHOULD provide this header. A server may support any subset of the [Serialization Format Representations](https://hl7.org/fhir/resource-formats.html#wire). If omitted, the server MAY return an error or MAY process the request and return a format selected by the server.

- `Prefer` (string)

  Specifies whether the response is immediate or asynchronous. Setting this to <a href="https://datatracker.ietf.org/doc/html/rfc7240#section-4.1"><code>respond-async</code></a> triggers this asynchronous bulk pattern, though operations that can only be invoked asynchronously MAY default to this behavior or MAY return an error when this header is not provided.

  A client MAY also provide a second Prefer header value of `separate-export-status`, so the combined Prefer header for the kick-off request is `Prefer: respond-async,separate-export-status`. If this header value is included by a client and is supported by a server, the server SHALL return the header `Preference-Applied` with values of `respond-async` and `separate-export-status` in its response. These may be provided as comma-delimited values or the header may be repeated for each value.

  When a Prefer header value of `separate-export-status` is provided in the kick-off request and supported by the server, the HTTP status code in the response to a Bulk Data Status Request SHALL reflect the status request itself, and not the asynchronous job. In this case, when the HTTP status code of the Bulk Data Status Request is `200 OK`, the response SHALL also include an `X-Export-Status` header with an HTTP status code that reflects the status of the asynchronous job.

##### Parameters

{% include async-query-parameters.md %}

[View OperationDefinition for FHIR Asynchronous Bulk Interaction Pattern](OperationDefinition-async.html)

Implementation notes:

- If neither `_minimumFileSize` nor `_maximumFileSize` is specified, servers use their default file size behavior.
- Servers MAY deviate from the specified `_minimumFileSize` and `_maximumFileSize` when necessary, for example for the last file in a sequence or when a resource is larger than `_maximumFileSize`.
- Servers SHOULD document any fixed file size bounds they implement.

##### Response - Success

- HTTP Status Code of `202 Accepted`
- `Content-Location` header with the absolute URL of an endpoint for subsequent status requests
- When a Prefer header value of `separate-export-status` is provided in the kick-off request and supported by the server, the response SHALL include the header `Preference-Applied` with values of `respond-async` and `separate-export-status`. These may be provided as comma-delimited values or the header may be repeated for each value.
- Optionally, a FHIR `OperationOutcome` resource in the body

##### Response - Error

- HTTP Status Code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource

---
{% include async-status-polling-request.md %}

##### Response - Output Manifest

{% include async-output-manifest.md %}

---
{% include async-output-file-request.md %}

##### Bulk Data Output File Organization

Output files may be organized by resource type, or by instances of a resource type specified in the `outputOrganizedBy` element of the output manifest.

When the `outputOrganizedBy` element in the manifest is not populated, each output file SHALL contain resources of only one type, and a {{ bulk_server_role }} MAY create more than one file for each resource type returned. The number of resources contained in a file MAY vary between {{ bulk_server_role }}s and files.

When the `outputOrganizedBy` element is populated with a resource type, the output files SHALL be populated with blocks consisting of a header `Parameters` resource containing a parameter named `header` with a reference to a resource of the type specified by `outputOrganizedBy`, followed by the resource referenced in this header and resources that reference the resource referenced in the header (together a "resource block"). Each output file MAY contain multiple resource blocks and, when possible, a single resource's block SHOULD NOT be split across files. If a resource block does span more than one file, the header SHALL be repeated at the start of each file where the block continues, and the association between these files SHALL be documented in the manifest using the `continuesInFile` element in the relevant `output` array items.

Resources that would otherwise be included in the returned data set, but do not have references to the resource type specified in the `outputOrganizedBy` element, MAY be included in resource blocks that contain resources they reference, MAY be repeated in every resource block, or MAY be omitted from the data set.

<div class="stu-note">
When the <code>outputOrganizedBy</code> element is set to <code>Patient</code>, {{ bulk_server_role }}s SHOULD use the <a href="https://www.hl7.org/fhir/compartmentdefinition-patient.html">Patient Compartment Definition</a> to determine a base set of related resources to include in a resource block, though other resources may also be included.

For other resource types, we are soliciting feedback on the best approach for documenting the set of resources in a resource block. Implementation Guides MAY reference a <a href="https://www.hl7.org/fhir/compartmentdefinition.html">Compartment Definition</a>, populate a <a href="https://www.hl7.org/fhir/graphdefinition.html">GraphDefinition Resource</a>, include narrative text, or use another approach.
</div>

Example NDJSON file when the manifest does not include `outputOrganizedBy`:

```js
{"id":"p-1","resourceType":"Patient", "name":[{"given":["Brenda"],"family":"Jackson"}],"gender":"female", ...}
{"id":"p-2","resourceType":"Patient", "name":[{"given":["Bram"],"family":"Sandeep"}],"gender":"male", ...}
{"id":"p-3","resourceType":"Patient", "name":[{"given":["Sandy"],"family":"Hamlin"}],"gender":"female", ...}
{...}
```

<a name="submit-status-organize-output-by-file-example"></a>

Example NDJSON file when `outputOrganizedBy` is set to `Patient`:

```js
{"resourceType": "Parameters", "parameter": [{"name": "header", "valueReference": {"reference": "Patient/p-1"}}]}
{"id": "p-1", "resourceType": "Patient", ...}
{"id": "c-1", "resourceType": "Condition", "subject":{"reference": "Patient/p-1"}, ...}
{"id": "o-1", "resourceType": "Observation", "subject":{"reference": "Patient/p-1"}, ...}
{...}
{"resourceType": "Parameters", "parameter": [{"name": "header", "valueReference": {"reference": "Patient/p-2"}}]}
{"id": "p-2", "resourceType": "Patient", ...}
{"id": "c-101", "resourceType": "Condition", "subject":{"reference": "Patient/p-2"}, ...}
{"id": "o-102", "resourceType": "Observation", "subject":{"reference": "Patient/p-2"}, ...}
{...}
```

{% include async-attachments.md %}

---
{% include async-delete-request.md %}
