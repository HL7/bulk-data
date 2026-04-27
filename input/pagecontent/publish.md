### Audience and Scope

The Bulk Publish operation is intended to be used by developers at organizations that aim to interoperate by sharing large FHIR datasets. It defines the application programming interfaces (APIs) through which a Data Consumer may retrieve FHIR bulk data files from a Data Provider. These files may be provided at an open endpoint, or may require the Data Consumer to authenticate and authorize access to retrieve the data.

The Bulk Publish API does not require a FHIR server implementation, and Data Providers may implement it using a simple HTTP server that returns a Bulk Publish manifest in response to GET requests at a path that ends in `/$bulk-publish`, and a set of HTTP endpoints that serve the bulk data files referenced from that manifest.

For a high-level comparison of Bulk Export, Bulk Submit, and Bulk Publish, see [Choosing a Bulk Operation](index.html#choosing-a-bulk-operation).

#### Relationship to Bulk Export

In contrast to the [Bulk Export operation](export.html), the Bulk Publish operation returns static manifests and bulk data files, and does not provide a mechanism for a Data Consumer to retrieve a filtered subset of the available data. Systems that return infrequently updated reference information may wish to use the Bulk Publish operation instead of the Bulk Export operation to reduce the complexity and cost involved in hosting and providing this information. 

Expected use cases include the publication of provider directory information, formulary information and open scheduling slots.

### Security Considerations

All exchanges described herein between a Data Consumer and a Data Provider SHOULD be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://tools.ietf.org/html/rfc5246) or a more recent version of TLS. Use of mutual TLS is OPTIONAL. With each of the requests described herein, implementers MAY implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html).

### Roles

There are two primary roles involved in a Bulk Publish transaction:

1. **Data Provider**: Server that hosts the Bulk Publish manifest and file listed in the manifest.

2. **Data Consumer**: Client that retrieves the Bulk Publish manifest and bulk data files and attachments.


### Manifest Request

Request for fully static or periodically updated dataset in FHIR format. For a visual overview of how a Data Consumer processes a Bulk Publish manifest, see the [Data Consumer Workflow](#data-consumer-workflow) diagram below.

#### Endpoint

GET `[base]/$bulk-publish`

- A Data Provider SHALL support retrieval of a Bulk Publish manifest through an HTTP GET request to an endpoint that terminates with a `$bulk-publish` segment.
- A Data Consumer SHOULD include the conditional request HTTP header `If-None-Match` with each request to avoid retrieving data when nothing has changed since the last request. Data Providers SHOULD support the use of this header.
- When the `If-None-Match` value matches the current `ETag`, a Data Provider MAY return `304 Not Modified`; otherwise it SHALL return `200 OK` with the manifest.


#### Response - Error

- HTTP status code of `4XX` or `5XX`
- `Content-Type` header of `application/fhir+json`
- The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible (for example, the infrastructure layer returning the error is not FHIR aware), the Data Provider MAY return an error message in another format and include a corresponding value for the `Content-Type` header.


#### Response - Output Manifest

- HTTP status of `200 OK`
- `Content-Type` header of `application/json`
- `ETag` header that changes when the manifest body changes
- Body of output manifest (see below)

The output manifest is a JSON object providing metadata and links to the generated FHIR Bulk Data files. These files SHALL be accessible to the Data Consumer at the URLs advertised. The manifest and these URLs MAY be served by file servers other than the Data Provider's FHIR-specific server.

The Data Provider MAY update the manifest at any time and SHALL use the `transactionTime` element to indicate when the files were generated. The response SHOULD NOT include any FHIR resources modified after this instant, and SHALL include any matching resources modified up to and including this instant. File URLs SHALL not be reused between updates unless their contents have remained the same, and files SHOULD remain available for a grace period following an update to avoid interrupting downloads that are in progress.

The Data Provider SHOULD populate the `updateCadence` element to indicate the frequency with which the Data Provider expects to update the manifest.

Data Providers SHOULD set a reasonable `Cache-Control` header on the manifest (e.g., public, max-age=10) and SHOULD serve immutable files with long-lived caching headers (e.g., public, max-age=31536000, immutable).

##### Elements

{% include publish-manifest-fields.md %}


Implementation notes:

- For `transactionTime`, to properly meet the inclusion constraints above, a Data Provider might need to wait for pending updates in its publishing pipeline or source systems to resolve before publishing a new manifest.
- Error, warning, and information messages related to the published dataset or publication process SHOULD be included in `error` and not in `output`. If there are no relevant messages, the Data Provider SHOULD return an empty array. 


##### Incremental Updates

The Data Provider MAY incrementally update a manifest by adding data files to the `output` array element that contain new resources and/or resources that replace versions of the resources in earlier files in the `output` array that have the same resource id. Additionally, the Data Provider MAY add files with Bundle resources indicating resources that have been deleted to the `deleted` array element (see details below), and MAY add files to the `error` array element. When generating a manifest that will be subsequently updated with these incremental changes, the Data Provider SHALL populate an `epochStartTime` element. When initially published, this value SHALL have the same value as the `transactionTime` element. Subsequently, adding files to the `output` array, `deleted` array, and `error` array of a manifest will cause the `transactionTime` element for that manifest to advance, but the `epochStartTime` value will remain the same. If a Data Provider is refreshing the manifest and no resources have been added, deleted, or updated since the `transactionTime` in the current manifest, the Data Provider SHOULD advance the `transactionTime` to the current time to indicate that the Data Provider is regularly publishing updates. Periodically, the Data Provider MAY generate a manifest that is a complete snapshot of the data (a new epoch), updating the `output` array and `error` array, emptying the `deleted` array, and setting new `epochStartTime` and `transactionTime` values. When a manifest is incrementally updated, apart from when it is reset to a new epoch, the order of files in the `output`, `deleted`, and `error` arrays in the manifest SHALL not change, the file contents SHALL not change, and the files SHALL remain retrievable.

Data Providers SHALL structure the manifests such that a Data Consumer can obtain a complete data set when processing a manifest by (1) inserting or updating all FHIR resources in files in the `output` array that have not been previously processed, followed by (2) deleting all resources listed in files in the `deleted` array that have not been previously processed.

##### Examples

Minimal, non-incremental manifest:
<div class="language-json">
{% include Binary-BulkPublishManifestMinimalExample-html.xhtml %}
</div>
[View Example](Binary-BulkPublishManifestMinimalExample.html)

Example manifest at the epoch start:
<div class="language-json">
{% include Binary-BulkPublishManifestEpochStartExample-html.xhtml %}
</div>
[View Example](Binary-BulkPublishManifestEpochStartExample.html)

Manifest after first incremental update:
<div class="language-json">
{% include Binary-BulkPublishManifestIncrementalUpdateExample-html.xhtml %}
</div>
[View Example](Binary-BulkPublishManifestIncrementalUpdateExample.html)

Deleted resource bundle (represents one line in an output file):

<div class="language-json">
{% fragment Bundle/deleted-resource-transaction-bundle-example JSON ELIDE:language %}
</div>

[View Example](Bundle-deleted-resource-transaction-bundle-example.html)


---
### Bulk Data Output File Request

Using the URLs supplied by the Data Provider in the manifest, a Data Consumer MAY download the referenced output, deleted, and error files.

If the `requiresAccessToken` element in the manifest is set to `true`, the request SHALL include a valid access token.  See [Security Considerations](#security-considerations) above.

If the `requiresAccessToken` element is set to `false` and no additional authorization-related extensions are present in the relevant manifest entry, then the referenced URLs SHALL be dereferenceable directly (a "capability URL"). A Data Consumer SHALL NOT provide a SMART Backend Services access token when dereferencing a URL from a manifest entry where `requiresAccessToken` is `false`.

A single data file SHALL include only the most recent version of any resource, though manifests that are updated incrementally MAY include an updated version of the resource in a subsequent file. Inclusion of the `Resource.meta` information in the resources is at the discretion of the Data Provider (as it is for all FHIR interactions).

A Data Consumer SHOULD provide an `Accept-Encoding` header when requesting output files and SHOULD include `gzip` compression as one of the encoding options in the header. A Data Provider SHALL provide output files as uncompressed, with `gzip` compression, or with another compression format from the `Accept-Encoding` header. When compression is used, a Data Provider SHALL communicate this to the Data Consumer by including a `Content-Encoding` header in the response. A Data Consumer SHALL accept files that are uncompressed or encoded with `gzip` compression, and MAY accept files encoded with other compression formats.

#### Endpoint

`GET [url from manifest output, deleted, or error element]`

#### Headers

- `Accept` (optional, defaults to `application/fhir+ndjson`)

Specifies the format of the file being requested.

#### Response - Success

- HTTP status of `200 OK`
- `Content-Type` header that matches the file format being delivered.  For files in NDJSON format, SHALL be `application/fhir+ndjson`
- Body of FHIR resources in newline delimited json - [NDJSON](https://github.com/ndjson/ndjson-spec) or other requested format

#### Response - Error

- HTTP Status Code of `4XX` or `5XX`

### Bulk Data Output File Organization

Output files may be organized by resource type, or by instances of a resource type specified in the `outputOrganizedBy` element.

When the `outputOrganizedBy` element in the manifest is not populated, each output file SHALL contain resources of only one type, and a Data Provider MAY create more than one file for each resource type returned. The number of resources contained in a file MAY vary between Data Providers and files.

When the `outputOrganizedBy` element is populated with a resource type, the output files SHALL be populated with blocks consisting of a header `Parameters` resource containing a parameter named `header` with a reference to a resource of the type specified by `outputOrganizedBy`, followed by the resource referenced in this header and resources that reference the resource referenced in the header (together a "resource block"). Each output file MAY contain multiple resource blocks and, when possible, a single resource's block SHOULD NOT be split across files. If a resource block does span more than one file, the header SHALL be repeated at the start of each file where the block continues, and the association between these files SHALL be documented in the manifest using the `continuesInFile` element in the relevant `output` array items.

Resources that would otherwise be included in the data set, but do not have references to the resource type specified in the `outputOrganizedBy` element MAY be included in resource blocks that contain resources they reference, MAY be repeated in every resource block, or MAY be omitted from the data set.

<div class="stu-note">
When the <code>outputOrganizedBy</code> element is set to <code>Patient</code>, Data Providers SHOULD use the <a href="https://www.hl7.org/fhir/compartmentdefinition-patient.html">Patient Compartment Definition</a> to determine a base set of related resources to include in a resource block, though other resources may also be included.

For other resource types, we are soliciting feedback on the best approach for documenting the set of resources in a resource block. Implementation Guides MAY reference a <a href="https://www.hl7.org/fhir/compartmentdefinition.html">Compartment Definition</a>, populate a <a href="https://www.hl7.org/fhir/graphdefinition.html">GraphDefinition Resource</a>, include narrative text, or use another approach.
</div>

Example NDJSON file when the manifest does not include `outputOrganizedBy`:

```js
{"id":"p-1","resourceType":"Patient", "name":[{"given":["Brenda"],"family":"Jackson"}],"gender":"female", ...}
{"id":"p-2","resourceType":"Patient", "name":[{"given":["Bram"],"family":"Sandeep"}],"gender":"male", ...}
{"id":"p-3","resourceType":"Patient", "name":[{"given":["Sandy"],"family":"Hamlin"}],"gender":"female", ...}
{...}
```

<a name="organize-output-by-file-example"></a>

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

#### Attachments

If resources in an output file contain elements of the type `Attachment`, the Data Provider SHOULD populate the `Attachment.contentType` code as well as either the `data` element or the `url` element. If the data element is not populated and the `url` element is populated, the `url` element SHALL be an absolute URL that can be dereferenced to the attachment's content.

When the `url` element is populated with an absolute URL and the `requiresAccessToken` element in the manifest is set to `true`, the URL location must be accessible by a Data Consumer with a valid access token, and SHALL NOT require the use of additional authentication credentials. When the `url` element is populated and the `requiresAccessToken` element in the manifest is set to `false`, the URL location must be accessible by a Data Consumer without an access token.

Note that if a Data Provider copies files to the Bulk Data output endpoint or proxies requests to facilitate access from this endpoint, it may need to modify the `Attachment.url` element when generating the Bulk Data output files.

### Data Consumer Workflow

<figure>
  {% include bulk-publish-data-consumer-workflow.svg %}
  <figcaption>Bulk Publish Data Consumer workflow.</figcaption>
</figure>

#### Error handling
- If any referenced file returns `404` or `410` while `epochStartTime` has not changed, the Data Provider is violating the invariant; Data Consumers MAY retry and/or alert.
- If the manifest becomes temporarily unreachable (e.g., 5xx), back off and retry (exponential backoff bounded by the `updateCadence`).
