### Audience and Scope

The Bulk Publish operation is intended to be used by developers at organizations that aim to interoperate by sharing large FHIR datasets. It defines the application programming interfaces (APIs) through which a Data Consumer may retrieve FHIR bulk data files from a Data Provider. These files may be provided at an open endpoint, or may require the Data Consumer to authenticate and authorize access to retrieve the data.

The Bulk Publish API does not require a FHIR server implementation, and Data Providers may implement it using a simple HTTP server that returns a Bulk Publish manifest in response to GET requests at a path that ends in `/$bulk-publish`, and a set of HTTP endpoints that serve the bulk data files referenced from that manifest.

For a high-level comparison of Bulk Export, Bulk Submit, and Bulk Publish, see [Choosing a Bulk Operation](index.html#choosing-a-bulk-operation).

#### Relationship to Bulk Export

In contrast to the [Bulk Export operation](export.html), the Bulk Publish operation returns static manifests and bulk data files, and does not provide a mechanism for a Data Consumer to retrieve a filtered subset of the available data. Systems that return infrequently updated reference information may wish to use the Bulk Publish operation instead of the Bulk Export operation to reduce the complexity and cost involved in hosting and providing this information.

Expected use cases include the publication of provider directory information, formulary information, and open scheduling slots.

### Security Considerations

All exchanges described herein between a Data Consumer and a Data Provider SHOULD be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://tools.ietf.org/html/rfc5246) or a more recent version of TLS. Use of mutual TLS is OPTIONAL. With each of the requests described herein, implementers MAY implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html).

### Roles

There are two primary roles involved in a Bulk Publish transaction:

1. **Data Provider**: Server that hosts the Bulk Publish manifest and files listed in the manifest.

2. **Data Consumer**: Client that retrieves the Bulk Publish manifest and bulk data files and attachments.


### Manifest Request

A Data Consumer requests the manifest describing a fully static or periodically updated dataset in FHIR format.

#### Endpoint

GET `[base]/$bulk-publish`

- A Data Provider SHALL support retrieval of a Bulk Publish manifest through an HTTP GET request to an endpoint that terminates with a `$bulk-publish` segment.
- A Data Consumer SHOULD include the conditional request HTTP header `If-None-Match` with each request when it has a previously received `ETag` value to avoid retrieving data when nothing has changed since the last request. Data Providers MAY support the use of this header.
- When the `If-None-Match` value matches the current `ETag`, a Data Provider MAY return `304 Not Modified`.

#### Response - Manifest

The Data Provider SHALL return a manifest response with:

- HTTP status `200 OK`
- `Content-Type` header of `application/json`
- Body of a root manifest page (see [Manifest Elements](#manifest-elements))

The response MAY include an `ETag` header. When included, the `ETag` value SHALL change when the manifest body changes.

A manifest page is a JSON object providing metadata and links to the generated FHIR Bulk Data files. These files SHALL be accessible to the Data Consumer at the URLs advertised. The manifest and these URLs MAY be served by file servers other than the server hosting the manifest endpoint.

The Data Provider MAY update the manifest at any time and SHALL use the `transactionTime` element to indicate when the files were generated. The files referenced by the manifest SHOULD NOT include any FHIR resources modified after this instant, and SHALL include any matching resources modified up to and including this instant. File URLs SHALL NOT be reused between updates unless their contents have remained the same, and files that no longer appear in a manifest SHOULD remain available for a grace period following an update to avoid interrupting downloads that are in progress.

The Data Provider SHOULD populate the `updateCadence` element to indicate the frequency with which the Data Provider expects to update the manifest.

Data Providers SHOULD set a reasonable `Cache-Control` header on the manifest (e.g., public, max-age=10) and SHOULD serve immutable files with long-lived caching headers (e.g., public, max-age=31536000, immutable).

The `output`, `deleted`, and `error` arrays describe downloadable files. Files listed in `output` contain FHIR resources to insert or update. Files listed in `deleted` contain FHIR transaction Bundles whose entries identify resources to delete. Files listed in `error` contain OperationOutcome resources with errors, warnings, success, or informational messages about the dataset or publication process. For a given file URL, file contents are immutable: if the content changes, the Data Provider SHALL publish it at a new URL.

A Data Provider MAY divide a large manifest into multiple manifest pages, by including a single instance of a `link` element that has a `relation` element with a value of `next`, and a `url` element pointing to the location of another manifest. All fields in the linked manifest SHALL be populated with the same values as the manifest with the link, apart from the `output`, `deleted`, `error`, and `link` arrays.

These `next` links represent ordinary manifest paging: the pages together describe one published dataset available when the Data Consumer starts retrieval. A Data Consumer follows ordinary `next` URLs until no `next` link is present.

A Data Consumer SHALL process a manifest one page at a time by (1) inserting or updating all FHIR resources in files in the `output` array in array order, followed by (2) deleting all resources listed in files in the `deleted` array in array order. When the same resource type and logical id appear more than once, the Data Consumer SHALL keep the latest version by manifest order, unless it is later removed by a `deleted` entry. Files listed in the `error` array are informational. They convey errors, warnings, and information messages about the dataset or publication process and are not inserted into or deleted from the Data Consumer's dataset.

Example simple manifest:

```
GET https://example.com/$bulk-publish
```

<div class="language-json">
{% include Binary-BulkPublishManifestMinimalExample-html.xhtml %}
</div>

[View Example](Binary-BulkPublishManifestMinimalExample.html)

Example manifest with pages:

```
GET https://example.com/$bulk-publish
```

<div class="language-json">
{% include Binary-BulkPublishManifestPagedExample-html.xhtml %}
</div>

[View Example](Binary-BulkPublishManifestPagedExample.html)

Example next manifest page:

```
GET https://example.com/manifests/provider-directory-page-2.json
```

<div class="language-json">
{% include Binary-BulkPublishManifestPagedNextPageExample-html.xhtml %}
</div>

[View Example](Binary-BulkPublishManifestPagedNextPageExample.html)

#### Response - Error

The Data Provider SHALL return an error response with HTTP status `4XX` or `5XX`.

The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible (for example, the infrastructure layer returning the error is not FHIR aware), the Data Provider MAY return an error message in another format and include a corresponding value for the `Content-Type` header.

When the body is a FHIR `OperationOutcome` resource, the response SHALL include a `Content-Type` header of `application/fhir+json`.

#### Incremental Updates

Separately from ordinary manifest paging, a Data Provider MAY provide manifests of files that incrementally update the dataset included in the root manifest (a "manifest chain"). When doing so, the Data Provider SHALL indicate to the Data Consumer that it will be adding additional pages to the manifest chain by including a single `link` element with a `relation` that has a value of `next` and a `url` element that has a value of `#pending` in the last page of the manifest chain.

For a visual overview of how a Data Consumer processes a Bulk Publish manifest that may include incremental updates, see the [Manifest Retrieval Flow](#manifest-retrieval-flow) diagram below.

The `link` element in the manifest page returned at `[base]/$bulk-publish` SHALL NOT include a `url` with a value of `#pending`. To indicate that additional pages will be added to it with incremental updates, the Data Provider SHALL include a single instance of a `link` element that has a `relation` element with a value of `next`, and a `url` element pointing to the location of a "stub" manifest that does not contain files, but does contain a `#pending` next link URL.

When an incremental update is available, the Data Provider SHALL update the link element in the last manifest page in the chain from `#pending` to the URL of the new manifest page. The Data Provider SHOULD periodically update the snapshot manifest at `[base]/$bulk-publish` with changes that have accrued since the last update, so a new client doesn't need to follow the entire chain to retrieve a full dataset.

A Data Consumer SHOULD monitor the last manifest page in the chain with a link URL of `#pending` for changes and follow the next link URL when it is populated.

A Data Provider SHALL end a manifest chain and indicate that a Data Consumer should reset their dataset to a new snapshot by replacing a `#pending` link URL value with a value of `#closed`, or by replacing the `#pending` link URL with a manifest that has a next link URL of `#closed`. Once a manifest advertises `#closed`, it is final and may not be mutated.

As with requests at `[base]/$bulk-publish`, when checking if a previously retrieved manifest has been updated, a Data Consumer SHOULD include the conditional request HTTP header `If-None-Match` when it has a previously received `ETag` value to avoid retrieving data when nothing has changed since the last request. Data Providers MAY support the use of this header, and when the `If-None-Match` value matches the current `ETag`, a Data Provider MAY return `304 Not Modified`.

Manifests with a next link URL of `#pending` MAY carry an `ETag` and SHOULD NOT be served with long-lived immutable caching until finalized.

If the manifest becomes temporarily unreachable (e.g., a 5xx error), a Data Consumer SHOULD back off and retry using exponential backoff bounded by the `updateCadence` of the manifest.

Example root manifest for an incremental update chain:

```
GET https://example.com/$bulk-publish
```

<div class="language-json">
{% include Binary-BulkPublishManifestPendingRootExample-html.xhtml %}
</div>

[View Example](Binary-BulkPublishManifestPendingRootExample.html)

Example pending manifest page:

```
GET https://example.com/manifests/provider-directory-update-1.json
```

<div class="language-json">
{% include Binary-BulkPublishManifestPendingStubExample-html.xhtml %}
</div>

[View Example](Binary-BulkPublishManifestPendingStubExample.html)

Example incremental update manifest page:

```
GET https://example.com/manifests/provider-directory-update-1.json
```

<div class="language-json">
{% include Binary-BulkPublishManifestIncrementalUpdateExample-html.xhtml %}
</div>

[View Example](Binary-BulkPublishManifestIncrementalUpdateExample.html)

For a step-by-step example, see [Bulk Publish Worked Example](publish-worked-example.html).

#### Manifest Retrieval Flow

{% include publish-manifest-retrieval-flow.md %}

#### Manifest Elements

{% include publish-manifest-fields.md %}

Implementation notes:

- For `transactionTime`, to properly meet the inclusion constraints above, a Data Provider might need to wait for pending updates in its publishing pipeline or source systems to resolve before publishing a new manifest.
- Error, warning, and information messages related to the published dataset or publication process SHOULD be included in `error` and not in `output`.

Deleted resource bundle example (represents one line in a `deleted` file):

<div class="language-json">
{% fragment Bundle/deleted-resource-transaction-bundle-example JSON %}
</div>

[View Example](Bundle-deleted-resource-transaction-bundle-example.html)


---
### Bulk Data Output File Request

Using the URLs supplied by the Data Provider in the manifest, a Data Consumer MAY download the referenced output, deleted, and error files.

If the `requiresAccessToken` element in the manifest is set to `true`, the request SHALL include a valid access token. See [Security Considerations](#security-considerations) above.

If the `requiresAccessToken` element is set to `false` and no additional authorization-related extensions are present in the relevant manifest entry, then the referenced URLs SHALL be dereferenceable directly (a "capability URL"). A Data Consumer SHALL NOT provide a SMART Backend Services access token when dereferencing a URL from a manifest entry where `requiresAccessToken` is `false`.

A single data file SHALL include only the most recent version of any resource, though manifests that are updated incrementally MAY include an updated version of the resource in a subsequent file. Inclusion of the `Resource.meta` information in the resources is at the discretion of the Data Provider (as it is for all FHIR interactions).

A Data Consumer SHOULD provide an `Accept-Encoding` header when requesting output files and SHOULD include `gzip` compression as one of the encoding options in the header. A Data Provider SHALL provide output files as uncompressed, with `gzip` compression, or with another compression format from the `Accept-Encoding` header. When compression is used, a Data Provider SHALL communicate this to the Data Consumer by including a `Content-Encoding` header in the response. A Data Consumer SHALL accept files that are uncompressed or encoded with `gzip` compression, and MAY accept files encoded with other compression formats.

#### Endpoint

`GET [URL from manifest output, deleted, or error element]`

#### Headers

- `Accept` (optional, defaults to `application/fhir+ndjson`)

Specifies the format of the file being requested.

#### Response - Success

The Data Provider SHALL return a successful file response with:

- HTTP status `200 OK`
- `Content-Type` header that matches the file format being delivered
- Body of FHIR resources in [NDJSON](https://github.com/ndjson/ndjson-spec) - Newline-Delimited JSON, or other requested format

For files in NDJSON format, the `Content-Type` header SHALL be `application/fhir+ndjson`.

#### Response - Error

The Data Provider SHALL return an error response with HTTP status `4XX` or `5XX`.

### Bulk Data Output File Organization

Output files may be organized by resource type, or by instances of a resource type specified in the `outputOrganizedBy` element.

When the `outputOrganizedBy` element in the manifest is not populated, each output file SHALL contain resources of only one type, and a Data Provider MAY create more than one file for each resource type returned. The number of resources contained in a file MAY vary between Data Providers and files.

When the `outputOrganizedBy` element is populated with a resource type, the output files SHALL be populated with blocks consisting of a header `Parameters` resource containing a parameter named `header` with a reference to a resource of the type specified by `outputOrganizedBy`, followed by the resource referenced in this header and resources that reference the resource referenced in the header (together a "resource block"). Each output file MAY contain multiple resource blocks and, when possible, a single resource's block SHOULD NOT be split across files. If a resource block does span more than one file, the header SHALL be repeated at the start of each file where the block continues, and the association between these files SHALL be documented in the manifest using the `continuesInFile` element in the relevant `output` array items.

Resources that would otherwise be included in the dataset, but do not have references to the resource type specified in the `outputOrganizedBy` element, MAY be included in resource blocks that contain resources they reference, MAY be repeated in every resource block, or MAY be omitted from the dataset.

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

When the `url` element is populated with an absolute URL and the `requiresAccessToken` element in the manifest is set to `true`, the URL location SHALL be accessible by a Data Consumer with a valid access token, and SHALL NOT require the use of additional authentication credentials. When the `url` element is populated and the `requiresAccessToken` element in the manifest is set to `false`, the URL location SHALL be accessible by a Data Consumer without an access token.

Note that if a Data Provider copies files to the Bulk Data output endpoint or proxies requests to facilitate access from this endpoint, it may need to modify the `Attachment.url` element when generating the Bulk Data output files.

### Data Provider Algorithms

#### Publish a snapshot

A Data Provider may publish a new complete data snapshot at any time.

1. Generate the new snapshot files.

2. Publish a new root manifest at `[base]/$bulk-publish`:

   - a new `transactionTime`
   - `output` entries for the new snapshot
   - `deleted` and `error` entries when applicable
   - if the snapshot will be incrementally updated, a `next` link pointing to a manifest that contains a `next` link with a URL of `#pending`

---

#### Publish an incremental update

1. Prepare any new `output`, `deleted`, and `error` files.

2. Publish those files at URLs that will not be reused for different content.

3. Create the next manifest page at a static URL:

   - a new `transactionTime`;
   - `output`, `deleted`, and `error` entries for this step;
   - `link[relation="next"].url = "#pending"` unless the provider already knows the chain is capped.

4. Update the prior pending page so that its `next` link points to this manifest.

5. Optionally update the root manifest at `[base]/$bulk-publish` so new Data Consumers start from a fresher root snapshot.

---

#### Reconsolidate

A Data Provider may decide that old chains are no longer worth extending and may publish a new root snapshot instead.

1. Follow the steps described in [Publish a snapshot](#publish-a-snapshot)

2. Update any other pending manifest pages by changing their `next` link from a URL of `#pending` to `#closed`

3. Keep old files and manifests available for a reasonable grace period.
