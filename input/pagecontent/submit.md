## FHIR Bulk Submit Operation

### Audience and Scope

This implementation guide is intended to be used by developers at organizations that aim to interoperate by sharing large FHIR datasets. The guide defines the application programming interfaces (APIs) through which an authenticated and authorized system (Data Provider) may submit bulk FHIR data to a server (Data Consumer) and receive status information regarding the Data Consumer's receipt and processing of the data and, where applicable, processed data. The general purpose Bulk Submit operation can be implemented as defined here, or further profiled in implementation guides that constrain the options available in order to address a specific scenario.

Use cases include:
- A healthcare organization submitting data to a regulatory agency to meet a reporting requirement
- A healthcare organization sending healthcare data to a payer organization to support a quality measurement calculation
- A payer organization sharing data on claim status with a healthcare organization
- A healthcare organization moving data from a clinical system onto a standalone FHIR server to consolidate data from multiple systems in order to run analytic queries
- An organization providing FHIR data to an internal or external service to process the data for de-identification or other transformation
- An organization sharing a pre-defined dataset from a clinical system with another application, such as a care management tool

The scope of this document does NOT include:
- The activities a Data Consumer needs to do to validate and process the submitted data
- A legal framework for sharing data between partners, such as Business Associate Agreements, Service Level Agreements, and Data Use Agreements, though these may be required for some use cases
- Real-time data exchange
- Patient matching, although identifiers may be included in the submitted FHIR resources

#### Relationship to Bulk Export

The [FHIR Bulk Export API](https://build.fhir.org/ig/HL7/bulk-data/en/export.html) represents a pull-based approach. The client (Data Consumer) makes a kick-off request to a server (Data Provider), polls for export status, and, when files are ready, retrieves them from the Data Provider. This model is well suited for ad hoc data requests, where a client is trusted by the server and is able to provide filters describing the data required for a particular use.

In contrast, the Bulk Submit operation is a push-based approach where the Data Provider sends one or more manifests to the Data Consumer that describe a pre-coordinated data set. This model is well suited for cases where the required data is not ad hoc, and the Data Provider can determine the correct timing for sending data to the Data Consumer.

The Bulk Submit operation described in this document may be used together with Bulk Export through an intermediary application that first requests a bulk export to obtain a data set from a Bulk Export server, retrieves the data, optionally transforms it, and then submits the resulting data to the Data Consumer.

Note that a future update to the Bulk Export specification may incorporate the ability to specify a Bulk Submit endpoint in a Bulk Export [kick-off request](https://build.fhir.org/ig/HL7/bulk-data/export.html#bulk-data-kick-off-request) and have the export server directly initiate submission with the Bulk Submit operation when the export is complete.

### Roles

There are two primary roles involved in a Bulk Submit transaction:

1. **Data Provider**:

   a. **Submission Client**: Provides details on one or more bulk submission manifests to the Data Consumer and optionally tracks job status.

   b. **Submission File Server**: Returns files and attachments in response to URLs in the submission manifests. This may be integrated with a FHIR server, or the files may be independently hosted.

   c. **Authorization Server**: Issues access tokens and authenticates file requests to the Submission File Server.

2. **Data Consumer**:

   a. **Submission Server**: Accepts manifest details and provides job status.

   b. **Authorization Server**: Issues access tokens and authenticates manifest submission and job status requests.

   c. **File Retrieval Client**: Retrieves files listed in manifests from the Data Provider.

   d. **File Processor**: Processes submitted files with operations such as validation, quality metric calculation, and/or merging into an existing data set.

### Bulk Submit Operation

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

The Data Provider uses the `submissionStatus` parameter to indicate the state of a submission to the Data Consumer:

- `in-progress` or omitted: Indicates that there will be additional requests to the `$bulk-submit` endpoint for the `submitter` and `submissionId` combination in that request.
- `complete`: Indicates there will be no additional requests to the `$bulk-submit` endpoint for the `submitter` and `submissionId` combination in that request.
- `aborted`: Indicates that the submission is invalid. The Data Consumer must stop retrieving files and delete any data already processed from this submission. There will not be additional requests to the `$bulk-submit` endpoint for this `submitter` and `submissionId` combination.

###### Correcting Data Without Aborting

If a specific portion of the data is incorrect, the Data Provider should not cancel the entire submission. Instead, it should send a request that populates the `replacesManifestUrl` parameter. This tells the Data Consumer to discard the data from that specific previous manifest, and optionally replace it with a new `manifestUrl` when that element is also populated, while keeping the other manifests in the submission valid.

##### Security

The Data Consumer SHOULD implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](https://www.hl7.org/fhir/smart-app-launch/backend-services.html). When SMART Backend Services Authorization is used, the Data Provider SHALL use a token with a scope of `system/bulk-submit` when kicking off the `$bulk-submit` operation, kicking off the `$bulk-submit-status` operation, making a polling request to the endpoint provided from the kickoff, or retrieving files from status manifests returned by the operation.

If the `oauthMetadataUrl` parameter in the request is populated with the path to an [OAuth 2.0 Protected Resource Metadata file](https://datatracker.ietf.org/doc/rfc9728/), such as a [FHIR Authorization Endpoint and Capabilities Discovery file](https://hl7.org/fhir/smart-app-launch/conformance.html#using-well-known) for [SMART Backend Services](https://www.hl7.org/fhir/smart-app-launch/backend-services.html), the Data Consumer SHALL obtain and use a valid token when retrieving the manifest at `manifestUrl`. If `requiresAccessToken` in the retrieved manifest is also set to `true`, the Data Consumer SHALL obtain and use a token scoped to read the resource types included in the manifest when retrieving the referenced files.

If the `fileEncryptionKey` parameter in the request is set to `jwe`, the Data Provider SHALL use the key in `fileEncryptionKey.value` to encrypt the manifest and each file listed in the manifest's `output` section, and the Data Consumer SHALL use this key to decrypt those files.

If the `fileRequestHeader` parameter is included in the request, the Data Consumer SHALL provide the listed header name and value pairs when requesting a manifest or data file.

##### Manifest

When populated, the `manifestUrl` parameter SHALL contain a URL pointing to a valid [Bulk Data Manifest](StructureDefinition-BulkDataManifest.html). When a manifest is used in a submission, the deprecated `request` field MAY be omitted. The manifest MAY contain a `link` field, and when present, the Data Consumer SHALL follow this link to retrieve additional manifests.

Alternatively, the Data Provider MAY call the Bulk Submit operation multiple times, each with a different `manifestUrl`, using the same `submitter` and `submissionId` parameters to indicate that the contents of those manifests are part of a single submission. All operation parameters other than `submitter`, `submissionId`, and `submissionStatus` relate to the `manifestUrl` being sent and, when applicable, SHALL be included in the request even if they were populated in a previous request.

#### Request Headers

- `Accept` (string)
  Specifies the format of the optional FHIR `OperationOutcome` resource response to the request. Support for `application/fhir+json` is required. A client SHOULD provide this header. If omitted, the server MAY return an error or MAY process the request as if `application/fhir+json` was supplied.

#### Response - Success

- HTTP status code `200 OK`
- Optionally, a FHIR `OperationOutcome` resource in the body

#### Response - Error

- HTTP status code `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource

If a server wants to prevent a client from beginning a new submission before an in-progress submission is completed, it SHOULD respond with `429 Too Many Requests` and a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header, following the rate-limiting advice described in [Bulk Data Status Request](https://build.fhir.org/ig/HL7/bulk-data/export.html#bulk-data-status-request).

### Bulk Submit Status Operation

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
  Specifies the format of the optional FHIR `OperationOutcome` resource response to the kick-off request. Currently, only `application/fhir+json` is supported. A client SHOULD provide this header. If omitted, the server MAY return an error or MAY process the request as if `application/fhir+json` was supplied.

- `Prefer` (string)
  Specifies whether the response is immediate or asynchronous. Currently, only a value of <a href="https://datatracker.ietf.org/doc/html/rfc7240#section-4.1"><code>respond-async</code></a> is supported. A client SHOULD provide this header. If omitted, the server MAY return an error or MAY process the request as if `respond-async` was supplied.

#### Response - Success

- HTTP status code `202 Accepted`
- `Content-Location` header with the absolute URL of an endpoint for subsequent status requests
- Optionally, a FHIR `OperationOutcome` resource in the body in JSON format

#### Response - Error

- HTTP status code `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource in JSON format

If a server wants to prevent a client from beginning a new submission before an in-progress submission is completed, it SHOULD respond with `429 Too Many Requests` and a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header, following the rate-limiting advice for a [Bulk Data Status Request](https://build.fhir.org/ig/HL7/bulk-data/export.html#bulk-data-status-request).

### Bulk Data Status Polling Request

After a Bulk Submit Status request has been started, the request and response flow follows the [FHIR Asynchronous Request Pattern](https://www.hl7.org/fhir/R4/async.html).

The Data Consumer MAY return a partial status manifest and an HTTP status of `202 Accepted` while the submission is incomplete or is still being processed.

Once the submission is complete, meaning the Data Provider has sent a request with `submissionStatus = complete` and the Data Consumer has retrieved and processed the submitted files, the Data Consumer SHALL return a status manifest and an HTTP status of `200 OK`.

These manifests provide a mechanism for the Data Consumer to return resources related to the data submission. If there is no relevant information to communicate and the submission is complete, the Data Consumer MAY return a manifest with empty `output` and `error` arrays. Each manifest SHALL include `submissionId` at the root.

If there is status information to communicate, the Data Consumer SHALL populate the `error` section of the manifest with one or more files that contain OperationOutcome resources. For example, the Data Consumer may want to indicate that there are files from the Data Provider it was unable to retrieve, resources that failed validation, or resources that were not successfully merged into an existing data set. The number and granularity of the OperationOutcome resources returned by the Data Consumer depend on the use case and implementation. A Data Consumer may wish to return a set of high-level OperationOutcome resources indicating the status of each manifest submitted, more granular OperationOutcome resources indicating the status of each resource submitted, or both.

Each item in the `error` section of the manifest SHALL include `manifestUrl` to link the OperationOutcome file to the submitted manifest where the issue occurred. A single `manifestUrl` may be referenced from multiple items in the `error` section. Each `error` item SHALL also include `url`, pointing to a bulk file of OperationOutcome resources. If an issue is related to individual resources submitted by the Data Provider, the corresponding OperationOutcome SHOULD use the [artifact-relatedArtifact](https://build.fhir.org/ig/HL7/fhir-extensions/StructureDefinition-artifact-relatedArtifact.html) extension at its root to reference those resources. If an issue is related to a large number of resources, the Data Consumer SHOULD provide multiple OperationOutcome resources, each of which references a few of the submitted resources, to avoid making individual OperationOutcome resources extremely large. The Data Consumer MAY include `countSeverity`, populated as an array of `code` / `count` objects summarizing the `OperationOutcome.issue.severity` values present in that file.

If there are resources to return, the Data Consumer SHALL populate the `output` section of the manifest with one or more files that contain FHIR resources. Each item in the `output` section SHOULD include `manifestUrl` to link the returned file back to the submitted manifest. A single `manifestUrl` may be referenced from multiple items in the `output` section.

Generated field table from the logical model:

{% include submit-status-manifest-fields.md %}

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

### Bulk Submit Workflow

This example represents the workflow for a submission comprised of two manifests. As described above, the number of manifests in a submission may differ based on the use case and the volume of data being submitted.

<figure>
  {% include bulk-submit-workflow.svg %}
  <figcaption>PlantUML rendering of the Bulk Submit workflow</figcaption>
</figure>

### Underlying Standards

* [HL7 FHIR](https://www.hl7.org/fhir/)
* [Newline-delimited JSON](https://github.com/ndjson/ndjson-spec)
* [RFC5246, Transport Layer Security (TLS) Protocol Version 1.2](https://tools.ietf.org/html/rfc5246)
* [RFC6749, The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
* [RFC6750, The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750)
* [RFC7159, The JavaScript Object Notation (JSON) Data Interchange Format](https://tools.ietf.org/html/rfc7159)
* [RFC7240, Prefer Header for HTTP](https://tools.ietf.org/html/rfc7240)

### Terminology

This profile inherits terminology from the standards referenced above. The key words "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in [RFC2119](https://tools.ietf.org/html/rfc2119).

### Privacy and Security Considerations

All exchanges described herein between a client and a server SHALL be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://tools.ietf.org/html/rfc5246) or a more recent version of TLS. Use of mutual TLS is OPTIONAL.

The Bulk Submit Operation and Bulk Submit Status Operation SHOULD support OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html). When SMART Backend Services Authorization is used, Bulk Submit Status requests SHALL be protected the same way the Bulk Submit kick-off request is protected, including an access token with scopes that cover all resources being exported or returned. A server MAY additionally restrict Bulk Submit Status requests by limiting them to the client that originated the submission. Implementations MAY include endpoints that use authorization schemes other than OAuth 2.0, such as mutual TLS or signed URLs.

This implementation guide does not address protection of a server from potential compromise. An adversary who successfully captures administrative rights to the server will have full control over that server and can use those rights to undermine the server's security protections. In the Bulk Submit workflow, the file server will be a particularly attractive target, as it holds highly sensitive and valued PHI. An adversary who successfully takes control of a file server may choose to continue delivering files in response to client requests, so that neither the client nor the FHIR server is aware of the takeover. Meanwhile, the adversary is able to put the PHI to use for its own malicious purposes.

Healthcare organizations have an imperative to protect PHI persisted in file servers in both cloud and data-center environments. A range of existing and emerging approaches can be used to accomplish this, not all of which would be visible at the API level. This specification does not dictate a particular approach at this time, though it does support the use of an `Expires` header to limit the time period a file will be available for client download. Removal of the file from the server is left to the server implementer. A server SHOULD NOT delete files from a bulk data response that a client is actively in the process of downloading regardless of the pre-specified expiration time.

Data access control obligations can be met with a combination of in-band restrictions such as OAuth scopes and out-of-band restrictions, where the server limits the data returned to a specific client in accordance with local considerations such as policies or regulations. The FHIR server SHALL limit the data returned to only those FHIR resources for which the client is authorized. Implementers SHOULD incorporate technology that preserves and respects an individual's wishes to share their data with desired privacy protections. For example, some clients are authorized to access sensitive mental health information and some are not; this authorization is defined out of band, but when a client requests a full data set, filtering is automatically applied by the server, restricting the data that the client receives.

Bulk Submit can be a resource-intensive operation. Developers SHOULD consider and mitigate the risk of intentional or inadvertent denial-of-service attacks, though the details are beyond the scope of this specification. For example, transactional systems may wish to provide bulk data access to a read-only mirror of the database or may distribute processing over time to avoid loads that could impact clinical operations.
