{% assign bulk_server_role = "Data Consumer" %}
{% assign bulk_client_role = "Data Provider" %}
{% assign bulk_request_name = "a Bulk Submit Status request" %}
{% assign bulk_file_kind = "status files" %}
{% assign bulk_delete_note = "Cancelling a Bulk Submit Status request does not affect the submission; use `submissionStatus = stopped` to cancel a submission." %}
### Audience and Scope

The Bulk Submit operation is intended to be used by developers at organizations that aim to interoperate by sharing large FHIR datasets. It defines the application programming interfaces (APIs) through which an authenticated and authorized system (Data Provider) may submit bulk FHIR data to a server (Data Consumer) and receive status information regarding the Data Consumer's receipt and processing of the data and, where applicable, processed data. The general-purpose Bulk Submit operation can be implemented as defined here, or further profiled in implementation guides that constrain the options available in order to address a specific scenario.

For a high-level comparison of Bulk Export, Bulk Submit, and Bulk Publish, see [Choosing a Bulk Operation](index.html#choosing-a-bulk-operation).

#### Relationship to Bulk Export

Bulk Submit is the push-based complement to the pull-based [Bulk Export operation](export.html). In Bulk Submit, the Data Provider sends one or more manifests describing a pre-coordinated dataset to the Data Consumer. This is a better fit than Bulk Export when the sender already knows what must be delivered and the receiver needs in-band status or processing feedback.

Bulk Export is the better fit for ad hoc, data consumer-driven requests where the recipient needs to specify the cohort, filters, or time window.

Bulk Submit may also be used in conjunction with Bulk Export through an intermediary application that first requests a bulk export, retrieves the data, optionally transforms it, and then submits the resulting dataset to the Data Consumer.

In Bulk Submit, the roles are reversed relative to Bulk Export in several respects. The Data Consumer hosts the Submission Server, which the Data Provider invokes for both `$bulk-submit` and `$bulk-submit-status`. Submission data moves from the Data Provider to the Data Consumer: the Data Provider supplies URLs for the manifest and Bulk Data files, and the Data Consumer retrieves them. Status data can move in the opposite direction: the Data Consumer supplies URLs for files referenced by Bulk Submit Status manifests, and the Data Provider retrieves them from the Data Consumer's Status File Server.

### Privacy and Security Considerations

All exchanges described herein between a Data Consumer and a Data Provider SHALL be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://datatracker.ietf.org/doc/html/rfc5246) or a more recent version of TLS. Implementers MAY use mutual TLS.

The Data Consumer SHOULD implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html). When SMART Backend Services Authorization is used, the Data Provider SHALL use a token with a scope of `system/bulk-submit` when kicking off the `$bulk-submit` operation, kicking off the `$bulk-submit-status` operation, making a polling or delete request to the endpoint provided from the kickoff, or retrieving files listed in a status manifest whose `requiresAccessToken` is `true`.

### Roles

There are two primary roles involved in a Bulk Submit transaction:

1. **Data Provider**:

   a. **Submission Client**: Provides details on one or more bulk submission manifests to the Data Consumer and optionally tracks job status and, when applicable, job output.

   b. **Submission File Server**: Returns files and attachments in response to URLs in the submission manifests. This may be integrated with a FHIR server, or the files may be independently hosted. Although shown as a Data Provider role, the underlying storage may be provided by the Data Provider, the Data Consumer, or another party.

   c. **Authorization Server**: Issues access tokens and authenticates manifest and file requests to the Submission File Server, when that server is operated by the Data Provider.

2. **Data Consumer**:

   a. **Submission Server**: Accepts Bulk Submit requests, supports Bulk Submit Status requests and associated status polling, and returns status manifests.

   b. **Status File Server**: Returns files referenced by Bulk Submit Status manifests. This may be integrated with the Submission Server or the files may be independently hosted.

   c. **Authorization Server**: Issues access tokens and authenticates manifest submission, status requests, and, when applicable, requests for files referenced by status manifests.

   d. **File Retrieval Client**: Retrieves submitted manifests and the files they list from the Submission File Server.

   e. **File Processor**: Processes submitted files with operations such as validation, quality metric calculation, and/or merging into an existing data set.

### Sequence Overview

This example represents the workflow for a submission comprised of two manifests. The number of manifests in a submission may differ based on the use case and the volume of data being submitted.

The sequence diagram illustrates the components that participate directly in the Bulk Submit protocol exchanges. Components involved only in internal processing, such as the File Processor, and authorization interactions are omitted for clarity. Components shown separately may also be combined within a single implementation.

<figure>
  {% include bulk-submit-workflow.svg %}
  <figcaption>Example of the Bulk Submit request flow.</figcaption>
</figure>


### Bulk Submit Request Flow

#### Request (Data Consumer Endpoint)

```
POST [fhir base]/$bulk-submit
```

[View OperationDefinition for Bulk Submit](OperationDefinition-bulk-submit.html)

##### Parameters

The request body SHALL be a FHIR [Parameters resource](https://hl7.org/fhir/parameters.html) with the following parameters:

{% include submit-bulk-submit-parameters.md %}

Constraints:
- At least one of the `submissionStatus` and `manifestUrl` parameters SHALL be populated.
- When the `manifestUrl` parameter is populated, `fhirBaseUrl` SHALL be populated.

##### `submissionStatus` Parameter

The Data Provider uses the `submissionStatus` parameter to indicate the state of a submission to the Data Consumer. Values SHALL be drawn from the [Submission Status Value Set](ValueSet-submission-status.html), which constrains the [`http://hl7.org/fhir/event-status`](https://hl7.org/fhir/valueset-event-status.html) code system. These values have the following meanings:

- `in-progress` (default if parameter is omitted): Additional requests to the `$bulk-submit` endpoint are expected for the `submitter` and `submissionId` combination in that request.
- `completed`: The Data Provider SHALL NOT send additional requests to the `$bulk-submit` endpoint for the `submitter` and `submissionId` combination in that request.
- `stopped`: The submission is invalid. The Data Consumer SHALL stop retrieving files and SHOULD delete any data already processed from this submission. The Data Provider SHALL NOT send additional requests to the `$bulk-submit` endpoint for this `submitter` and `submissionId` combination.

###### Correcting Data Without Aborting

If a specific portion of the data is incorrect, the Data Provider SHOULD NOT cancel the entire submission. Instead, it SHOULD send a request that populates the `replacesManifestUrl` parameter. This tells the Data Consumer to discard the data from that specific previous manifest, and optionally replace it with a new `manifestUrl` when that element is also populated, while keeping the other manifests in the submission valid.

##### Manifest and File Security

If the `oauthMetadataUrl` parameter in the request is populated with the path to an [OAuth 2.0 Protected Resource Metadata file](https://datatracker.ietf.org/doc/rfc9728/), such as a [FHIR Authorization Endpoint and Capabilities Discovery file](https://hl7.org/fhir/smart-app-launch/conformance.html#using-well-known) for [SMART Backend Services](authorization.html), the Data Consumer SHALL obtain and use a valid token when retrieving the manifest at `manifestUrl`. If `requiresAccessToken` in the retrieved manifest is also set to `true`, the Data Consumer SHALL obtain and use a token scoped to read the resource types included in the manifest when retrieving the referenced files. If `oauthMetadataUrl` is not supplied and `requiresAccessToken` in the retrieved manifest is `true`, the access token is obtained by prior arrangement between the Data Provider and the Data Consumer.

Files exchanged in a Bulk Submit workflow MAY be encrypted. A future release of the FHIR Extensions Pack is expected to define a standard extension for conveying file encryption key information; implementers who need encryption before then should coordinate the mechanism out of band.

If the `fileRequestHeader` parameter is included in the request, the Data Consumer SHALL provide the listed header name and value pairs when requesting the OAuth metadata at `oauthMetadataUrl`, the manifest(s), and the files they reference.

##### Manifest

When populated, the `manifestUrl` parameter SHALL contain a URL pointing to a valid [Bulk Data Manifest](StructureDefinition-BulkDataManifest.html) that contains the bulk data files being submitted. If a submitted manifest includes an `outputFormat` element and the `$bulk-submit` request includes an `outputFormat` parameter, the two values are expected to match. The manifest MAY contain a `link` field, and when present, the Data Consumer SHALL follow this link to retrieve additional manifests.

Alternatively, the Data Provider MAY call the Bulk Submit operation multiple times, each with a different `manifestUrl`, using the same `submitter` and `submissionId` parameters to indicate that the contents of those manifests are part of a single submission. All operation parameters other than `submitter`, `submissionId`, and `submissionStatus` relate to the `manifestUrl` being sent and, when applicable, SHALL be included in the request even if they were populated in a previous request.

###### Consumer-provided Upload Locations

As an optional deployment pattern, a Data Consumer may provide a location where the Data Provider can upload files before invoking `$bulk-submit`. The Data Provider can upload Bulk Data files and, optionally, manifest files to this location and then use the resulting URLs in the normal Bulk Submit workflow.

The mechanism used to upload these files is outside the scope of this specification. For example, a Data Consumer might provide a FHIR `Binary` endpoint or object storage upload URLs.

This pattern does not change `$bulk-submit`, the manifest format, or Bulk Submit Status processing. URLs submitted through `manifestUrl` or included in a manifest may therefore identify storage provided by the Data Consumer rather than infrastructure operated by the Data Provider.

##### Headers

- `Accept` (string)
  Specifies the format of the optional FHIR `OperationOutcome` resource response to the request. The Data Consumer SHALL support `application/fhir+json`. A Data Provider SHOULD provide this header. If omitted, the Data Consumer MAY return an error or MAY process the request as if `application/fhir+json` was supplied.

##### Response - Success

The Data Consumer SHALL return a successful response with HTTP status `200 OK`.

The Data Consumer MAY include a FHIR `OperationOutcome` resource in the body.

##### Response - Error

The Data Consumer SHALL return an error response with:

- HTTP status `4XX` or `5XX`
- FHIR `OperationOutcome` resource in the body

If a Data Consumer wants to prevent a Data Provider from beginning a new submission before an in-progress submission is completed, it SHOULD respond with `429 Too Many Requests`.

### Processing Submissions

Depending on use case, Data Consumers may process submitted data in different ways, including validating resources, calculating metrics, loading a FHIR server, transforming data, or combining it with other datasets.

Bulk Submit does not require FHIR transaction processing or storage in a FHIR repository. Consumers that store resources can preserve submitted resource ids or assign local ids. Beyond its explicit replacement and cancellation requirements, the operation does not prescribe a general policy for resolving local id collisions or deciding whether to create, update, or merge records.

The `fhirBaseUrl` parameter, together with resource type and id, identifies a resource in its source namespace. Data Consumers can use this identity to recognize a resource within and across submissions.

### Bulk Submit Status Request Flow

After a Data Provider has kicked off a Bulk Submit operation, it may wish to receive updates on the status of the submission. For example, a Data Consumer may indicate files it was unable to retrieve, resources that failed validation, or resources that were not able to be merged into an existing data set. Additionally, the Data Consumer may need to return processed data back to the Data Provider, such as computed quality measures or a de-identified version of the submitted data. The Bulk Submit Status operation provides a way for a Data Provider to request resources related to a submission from the Data Consumer.

#### Kick-off Request

```
POST [fhir base]/$bulk-submit-status
```

[View OperationDefinition for Bulk Submit Status](OperationDefinition-bulk-submit-status.html)

##### Parameters

The request body SHALL be a FHIR [Parameters resource](https://hl7.org/fhir/parameters.html) with the following parameters:

{% include submit-bulk-submit-status-parameters.md %}

##### Headers

- `Accept` (string)
  Specifies the format of the optional FHIR `OperationOutcome` resource response to the kick-off request. The Data Consumer SHALL support `application/fhir+json`. A Data Provider SHOULD provide this header. If omitted, the Data Consumer MAY return an error or MAY process the request as if `application/fhir+json` was supplied.

- `Prefer` (string)
  Specifies whether the response is immediate or asynchronous. A value of <a href="https://datatracker.ietf.org/doc/html/rfc7240#section-4.1"><code>respond-async</code></a> indicates that the response is asynchronous. A Data Provider SHOULD provide this header. If omitted, the Data Consumer MAY return an error or MAY process the request as if `respond-async` was supplied.

  A Data Provider MAY also provide a second Prefer header value of `separate-export-status`, so the combined Prefer header for the kick-off request is `Prefer: respond-async,separate-export-status`. If this header value is included by a Data Provider and is supported by a Data Consumer, the Data Consumer indicates this with a `Preference-Applied` header, as described under Response - Success below.

  When a Prefer header value of `separate-export-status` is provided in the kick-off request and supported by the Data Consumer, the HTTP status code in the response to a Bulk Data Status Request SHALL reflect the status request itself, and not the asynchronous job. In this case, when the HTTP status code of the Bulk Data Status Request is `200 OK`, the response SHALL also include an `X-Export-Status` header with an HTTP status code that reflects the status of the asynchronous job.

##### Response - Success

The Data Consumer SHALL return a successful kick-off response with:

- HTTP status `202 Accepted`
- `Content-Location` header with the absolute URL of an endpoint for subsequent status requests

When a Prefer header value of `separate-export-status` is provided in the kick-off request and supported by the Data Consumer, the response SHALL include the header `Preference-Applied` with values of `respond-async` and `separate-export-status`. These may be provided as comma-delimited values or the header may be repeated for each value.

The Data Consumer MAY include a FHIR `OperationOutcome` resource in the body in JSON format.

##### Response - Error

The Data Consumer SHALL return an error response with:

- HTTP status `4XX` or `5XX`
- FHIR `OperationOutcome` resource in the body in JSON format

---
{% include async-status-polling-request.md %}

##### Response - Output Manifest

The Data Consumer MAY return a partial status manifest in an in-progress status response (see [Response - In-Progress Status](#response---in-progress-status)) while the submission is incomplete or is still being processed.

Once the submission is complete, meaning the Data Provider has sent a request with `submissionStatus = completed` and the Data Consumer has retrieved and processed the submitted files, the Data Consumer SHALL return a status manifest and an HTTP status of `200 OK`.

These manifests provide a mechanism for the Data Consumer to return resources related to the data submission. If there is no relevant information to communicate and the submission is complete, the Data Consumer MAY omit `output` and `outcome`. Each manifest SHALL include `submissionId` at the root.

If there is status information to communicate, the Data Consumer SHALL populate the `outcome` section of the manifest with one or more files that contain OperationOutcome resources. For example, the Data Consumer may want to indicate that there are files from the Data Provider it was unable to retrieve, resources that failed validation, or resources that were not successfully merged into an existing data set. The number and granularity of the OperationOutcome resources returned by the Data Consumer depend on the use case and implementation. A Data Consumer may wish to return a set of high-level OperationOutcome resources indicating the status of each manifest submitted, more granular OperationOutcome resources indicating the status of each resource submitted, or both.

Successful completion of submission processing does not imply acceptance of every submitted resource. Use case IGs can describe how senders reconcile partial acceptance using status manifests and OperationOutcome resources, including how reported issues inform correction and retry.

Each item in the `outcome` section of the manifest SHALL include `manifestUrl` to link the OperationOutcome file to the submitted manifest where the issue occurred. A single `manifestUrl` may be referenced from multiple items in the `outcome` section. Each `outcome` item SHALL also include `url`, pointing to a bulk file of OperationOutcome resources. If an issue is related to individual resources submitted by the Data Provider, the corresponding OperationOutcome SHOULD use the [`operationoutcome-resource`](https://hl7.org/fhir/extensions/StructureDefinition-operationoutcome-resource.html) extension at its root to reference those resources. If an issue is related to a large number of resources, the Data Consumer SHOULD provide multiple OperationOutcome resources, each of which references a few of the submitted resources, to avoid making individual OperationOutcome resources extremely large. The Data Consumer MAY include `countSeverity`, populated as an array of `code` / `count` objects summarizing the `OperationOutcome.issue.severity` values present in that file.

If there are resources to return, the Data Consumer SHALL populate the `output` section of the manifest with one or more files that contain FHIR resources. Each item in the `output` section SHOULD include `manifestUrl` to link the returned file back to the submitted manifest. A single `manifestUrl` may be referenced from multiple items in the `output` section.

If the Data Consumer wishes to indicate that resources it previously returned in the `output` section of a status manifest for this submission should be removed by the Data Provider, the Data Consumer MAY populate the `deleted` section with one or more files containing FHIR transaction Bundles, as described in [Deleted Resources](#deleted-resources).

When the status response is returned incrementally, including when a partial status manifest is returned in an in-progress status response, the Data Consumer MAY populate the `link` section with a single object containing a `relation` field with a value of `next`, and a `url` field pointing to the location of another status manifest. All fields in the linked manifest SHALL be populated with the same values as the manifest with the link, apart from the `output`, `deleted`, `outcome`, and `link` arrays.

Generated field table from the logical model:

{% include submit-status-manifest-fields.md %}

The manifest logical models support standard FHIR extensions. Extensions may be added to the manifest itself or to individual elements as permitted by the logical model.

[View Bulk Submit Status Manifest logical model](StructureDefinition-BulkSubmitStatusManifest.html)

Example status manifest:

<div class="language-json">
{% include Binary-BulkSubmitStatusManifestExample-html.xhtml %}
</div>

[View Example](Binary-BulkSubmitStatusManifestExample.html)

Example OperationOutcome (resource-level status):

<div class="language-json">
{% include OperationOutcome-submit-status-resource-operationoutcome-example-json-html.xhtml %}
</div>

[View Example](OperationOutcome-submit-status-resource-operationoutcome-example.html)

Example OperationOutcome (manifest-level status):

<div class="language-json">
{% include OperationOutcome-submit-status-manifest-operationoutcome-example-json-html.xhtml %}
</div>

[View Example](OperationOutcome-submit-status-manifest-operationoutcome-example.html)

###### Deleted Resources

Files referenced by the Bulk Submit Status manifest's `deleted` array identify resources previously returned in the `output` of a status manifest for this submission that the Data Consumer is requesting the Data Provider to remove. The `request.url` in each entry identifies the resource as it appeared in that earlier `output`.

Each resource in a deleted resources file SHALL be a FHIR `Bundle` with `Bundle.type` set to `transaction`. Each Bundle SHALL contain one or more entries identifying resources to delete. For each entry, `request.url` SHALL identify the resource and `request.method` SHALL be `DELETE`.

For example, an NDJSON deleted resources file containing two deletion transactions could be:

```json
{"resourceType":"Bundle","type":"transaction","entry":[{"request":{"method":"DELETE","url":"Patient/123"}}]}
{"resourceType":"Bundle","type":"transaction","entry":[{"request":{"method":"DELETE","url":"Observation/456"}}]}
```

Resources that appear in a deleted resources file SHALL NOT also appear in an `output` file of the same manifest.

---
{% include async-delete-request.md %}

---
{% include async-output-file-request.md %}

#### Bulk Data Output File Organization

Output files may be organized by resource type, or by instances of a resource type specified in the `outputOrganizedBy` element.

When the `outputOrganizedBy` element in the status manifest is not populated, each output file SHALL contain resources of only one type, and a Data Consumer MAY create more than one file for each resource type returned. The number of resources contained in a file MAY vary between Data Consumers and files.

When the `outputOrganizedBy` element is populated with a resource type, the output files SHALL be populated with blocks consisting of a header `Parameters` resource containing a parameter named `header` with a reference to a resource of the type specified by `outputOrganizedBy`, followed by the resource referenced in this header and resources that reference the resource referenced in the header (together a "resource block"). Each output file MAY contain multiple resource blocks and, when possible, a single resource's block SHOULD NOT be split across files. If a resource block does span more than one file, the header SHALL be repeated at the start of each file where the block continues, and the association between these files SHALL be documented in the manifest using the `continuesInFile` element in the relevant `output` array items.

Resources that would otherwise be included in the returned data set, but do not have references to the resource type specified in the `outputOrganizedBy` element, MAY be included in resource blocks that contain resources they reference, MAY be repeated in every resource block, or MAY be omitted from the data set.

<div class="stu-note">
When the <code>outputOrganizedBy</code> element is set to <code>Patient</code>, Data Consumers SHOULD use the <a href="https://www.hl7.org/fhir/compartmentdefinition-patient.html">Patient Compartment Definition</a> to determine a base set of related resources to include in a resource block, though other resources may also be included.

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
