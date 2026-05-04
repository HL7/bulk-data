{% assign bulk_server_role = "Data Provider" %}
{% assign bulk_client_role = "Data Consumer" %}
### Audience and Scope

The Bulk Export operation is intended to be used by developers at organizations that aim to interoperate by sharing large FHIR datasets. It defines the application programming interfaces (APIs) through which an authenticated and authorized system (Data Consumer) may request a FHIR Data Export from another system (Data Provider), receive status information regarding progress in the generation of the requested files, and retrieve those files.  The data consumer can control the data being returned by optionally selecting the cohort, resource types, filters, data elements, and time window.

Many Bulk Export workflows are cohort-driven. A Data Provider may expose one or more FHIR Group resources representing payer rosters, research cohorts, quality-measure populations, care management panels, or other recurring populations. As described on [the Group page](group.html), implementations may expose read-only groups managed by the Data Provider, member-based groups managed by the Data Consumer, or criteria-based groups whose membership is computed from characteristics. Some Data Providers may also support the Bulk Cohort API described in this guide for asynchronous creation of characteristic-based cohorts by a Data Consumer. A group-level export, described below, provides a standard way to request data on patients in any of these types of groups.

For a high-level comparison of Bulk Export, Bulk Submit, and Bulk Publish, see [Choosing a Bulk Operation](index.html#choosing-a-bulk-operation).


### Privacy and Security Considerations

All exchanges described herein between a Data Consumer and a Data Provider SHALL be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://tools.ietf.org/html/rfc5246) or a more recent version of TLS. Use of mutual TLS is OPTIONAL.

The Data Provider SHOULD implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html). When SMART Backend Services Authorization is used, Bulk Data Status Requests and Bulk Data Output File Requests with `requiresAccessToken=true` SHALL be protected the same way as the Bulk Data Kick-off Request, including an access token with scopes that cover all resources being exported. A Data Provider MAY additionally restrict Bulk Data Status Requests and Bulk Data Output File Requests by limiting them to the Data Consumer that originated the export. Implementations MAY include endpoints that use authorization schemes other than OAuth 2.0, such as mutual TLS or signed URLs.

For Group level exports, in addition to requiring authorization to access the resources included in the export, a Data Provider SHOULD restrict Data Consumers from exporting data for Group resources they are not authorized to read (e.g., via `system/Group.rs` in SMART on FHIR v2). A Data Provider SHALL also restrict access to specific groups based on underlying business rules.

This implementation guide does not address protection of a Data Provider from potential compromise. An adversary who successfully captures administrative rights to the Data Provider will have full control over that system and can use those rights to undermine its security protections. In the Bulk Data Export workflow, the Data Provider's file server will be a particularly attractive target, as it holds highly sensitive and valued PHI. An adversary who successfully takes control of a file server may choose to continue to deliver files in response to Data Consumer requests, so that neither the Data Consumer nor the Data Provider's FHIR server is aware of the take-over. Meanwhile, the adversary is able to put the PHI to use for its own malicious purposes.

Healthcare organizations have an imperative to protect PHI persisted in file servers in both cloud and data-center environments. A range of existing and emerging approaches can be used to accomplish this, not all of which would be visible at the API level. This specification does not dictate a particular approach at this time, though it does support the use of an `Expires` header to limit the time period a file will be available for Data Consumer download. Removal of the file from the Data Provider is left to the implementer. A Data Provider SHOULD NOT delete files from a Bulk Data response that a Data Consumer is actively in the process of downloading regardless of the pre-specified expiration time.

Data access control obligations can be met with a combination of in-band restrictions (e.g., OAuth scopes) and out-of-band restrictions, where the Data Provider limits the data returned to a specific Data Consumer in accordance with local considerations such as policies or regulations. The Data Provider's FHIR server SHALL limit the data returned to only those FHIR resources for which the Data Consumer is authorized. Implementers SHOULD incorporate technology that preserves and respects an individual's wishes to share their data with desired privacy protections. For example, some Data Consumers are authorized to access sensitive mental health information and some are not; this authorization is defined out of band, but when a Data Consumer requests a full data set, filtering is automatically applied by the Data Provider, restricting the data that the Data Consumer receives.

Bulk Data Export can be a resource-intensive operation. Data Providers SHOULD consider and mitigate the risk of intentional or inadvertent denial-of-service attacks, though the details are beyond the scope of this specification. For example, transactional systems may wish to provide Bulk Data access to a read-only mirror of the database or may distribute processing over time to avoid loads that could impact clinical operations.

### Roles

There are two primary roles involved in a Bulk Data transaction:

1. **Data Provider**:

   a. **Authorization Server**: Issues access tokens in response to valid token requests from the Data Consumer.

   b. **FHIR Resource Server**: Accepts kick-off requests and provides job status and completion manifests.

   c. **Output File Server**: Returns FHIR bulk data files and attachments in response to URLs in the completion manifest. This may be built into the Data Provider's FHIR Resource Server, or the files may be independently hosted.

2. **Data Consumer**:

   a. **Export Client**: Requests the export and polls job status.

   b. **File Retrieval Client**: Retrieves bulk data files and attachments from the Data Provider.

### Sequence Overview

 <figure>
  {% include bulk-flow.svg %}
  <figcaption>Overview of the Bulk Data Export request flow.</figcaption>
</figure>

#### Kick-off Request

The Bulk Data Export Operation initiates the asynchronous generation of a requested export data set, whether that be data for all patients, data for a subset (defined group) of patients, or all FHIR data available from the Data Provider.

As discussed in [Privacy and Security Considerations](#privacy-and-security-considerations) above, a Data Provider SHALL limit the data returned to only those FHIR resources for which the Data Consumer is authorized.

The Data Provider's FHIR Resource Server SHALL support invocation of this operation using the [FHIR Asynchronous Bulk Interaction Pattern](async.html). A Data Provider SHALL support GET requests and MAY support POST requests that supply parameters using the FHIR [Parameters Resource](https://www.hl7.org/fhir/parameters.html).

If a parameter has a cardinality of greater than one, a Data Consumer MAY repeat the kick-off parameter multiple times or MAY include a single instance of the parameter with multiple values delimited by commas. The Data Provider SHALL treat comma-delimited values within a single instance of the parameter as if the parameter was repeated. The use of comma-delimited values within a parameter is deprecated in favor of repeating parameters and will be removed in a future version of this IG.

For Patient-level requests and Group-level requests associated with groups of patients, the [Patient Compartment](https://www.hl7.org/fhir/compartmentdefinition-patient.html) SHOULD be used as a point of reference for recommended resources to be returned and, where applicable, Patient resources SHOULD be returned. Other resources outside of the patient compartment that are helpful in interpreting the patient data (such as Organization and Practitioner) MAY also be returned.

Binary Resources whose content is associated with an individual patient SHALL be serialized as DocumentReference Resources with the `content.attachment` element populated as described in the [Attachments](#attachments) section below. Binary Resources not associated with an individual patient MAY be included in a System Level export.

References in the resources returned MAY be relative URLs with the format <code>&lt;resource type&gt;/&lt;id&gt;</code>, or MAY be absolute URLs with the same structure rooted in the base URL for the Data Provider's FHIR server from which the export was performed.

##### Endpoint - All Patients

`[fhir base]/Patient/$export`

[View table of parameters for Patient Export](OperationDefinition-patient-export.html)

FHIR Operation to obtain a detailed set of FHIR resources of diverse resource types pertaining to all patients.

##### Endpoint - Group of Patients

`[fhir base]/Group/[id]/$export`

[View table of parameters for Group Export](OperationDefinition-group-export.html)

FHIR Operation to obtain a detailed set of FHIR resources of diverse resource types pertaining to all members of a specified [Group](https://www.hl7.org/fhir/group.html).

If a Data Provider's FHIR server supports Group-level data export, it SHOULD support reading and searching for the `Group` resource. This enables Data Consumers to discover available groups based on stable characteristics such as `Group.identifier`.

As described on [the Group page](group.html), implementations may expose read-only groups managed by the Data Provider, member-based groups managed by the Data Consumer, or criteria-based groups whose membership is computed from characteristics. Some Data Providers may also support the Bulk Cohort API described in this guide for asynchronous creation of characteristic-based cohorts by a Data Consumer.

##### Endpoint - System Level Export

`[fhir base]/$export`

[View table of parameters for Export](OperationDefinition-export.html)

Export data from a Data Provider's FHIR server, whether or not it is associated with a patient. This supports use cases like backing up a Data Provider's FHIR server, or exporting terminology data by restricting the resources returned using the `_type` parameter.

##### Headers

- `Accept` (string)

  Specifies the format of the optional FHIR `OperationOutcome` resource response to the kick-off request. Currently, only `application/fhir+json` is supported. A Data Consumer SHOULD provide this header. If omitted, the Data Provider MAY return an error or MAY process the request as if `application/fhir+json` was supplied.

- `Prefer` (string)

  A Data Consumer SHOULD include this header with a value of <a href="https://datatracker.ietf.org/doc/html/rfc7240#section-4.1"><code>respond-async</code></a> to indicate that the export will be processed asynchronously. If omitted, the Data Provider MAY return an error or MAY process the request as if `respond-async` was supplied.

  A Data Consumer MAY also provide a second Prefer header value of `separate-export-status`, so the combined Prefer header for the kickoff request is `Prefer: respond-async,separate-export-status`. If this header value is included by a Data Consumer and is supported by a Data Provider, the Data Provider SHALL return the header `Preference-Applied` with values of `respond-async` and `separate-export-status` in its response. These may be provided as comma-delimited values or the header may be repeated for each value.

  When a Prefer header value of `separate-export-status` is provided in the kickoff request and supported by the Data Provider, the HTTP status code in the response to a Bulk Data Status request SHALL reflect the status request itself, and not the export job. In this case, when the HTTP status code of the Bulk Data Status request is `200 OK`, the response SHALL also include an `X-Export-Status` header with an HTTP status code that reflects the status of the export job.

##### Query Parameters

{% include export-query-parameters.md %}

*Note*: Implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/). If the Data Consumer explicitly asks for export of resources that the Data Provider does not support, the Data Provider SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request.

If an <code>includeAssociatedData</code> value relevant to provenance is not specified, or if this parameter is not supported by the Data Provider, the Data Provider SHALL include all available Provenance resources whose `Provenance.target` is a resource in the Patient compartment in a patient level export request, and all available Provenance resources in a system level export request unless a specific resource set is specified using the <code>_type</code> parameter and this set does not include Provenance.

##### Group Membership Request Pattern

To obtain new and updated resources for patients in a group, as well as all data for patients who have joined the group since a prior query, a Data Consumer can use the following pattern:

- Initial Query (e.g., on January 1, 2020):

  - Data Consumer submits a group export request:

    `[baseurl]/Group/[id]/$export`

  - Data Consumer retrieves response data
  - Data Consumer retains a list of the patient ids returned
  - Data Consumer retains the transactionTime value from the response

- Subsequent Queries (e.g., on February 1, 2020):
  - Data Consumer submits a group export request to obtain a patient list:

    `[baseurl]/Group/[id]/$export?_type=Patient&_elements=id`

  - Data Consumer retains a list of patient ids returned
  - Data Consumer compares the response to the patient ids from the first query and identifies new patient ids
  - Data Consumer submits a group export request via POST for patients who are new members of the group:

    ```
    POST [baseurl]/Group/[id]/$export

    {"resourceType" : "Parameters",
      "parameter" : [{
        "name" : "patient",
        "valueReference" : {reference: "Patient/123"}
      },{
        "name" : "patient",
        "valueReference" : {reference: "Patient/456"}
      ...
      }]
    }
    ```

  - Data Consumer submits a group export request for updated group data:

    `[baseurl]/Group/[id]/$export?_since=[initial transaction time]`

    Note that data returned from this request may overlap with that returned from the prior step.

  - Data Consumer retains the transactionTime value from the response.

##### `_typeFilter` Query Parameter

The `_typeFilter` parameter enables finer-grained filtering out of resources in the bulk data export response that would have otherwise been returned. For example, a Data Consumer may want to retrieve only active prescriptions rather than all prescriptions and only laboratory observations rather than all observations. When using `_typeFilter`, each resource type is filtered independently. For example, filtering `Patient` resources to people born after the year 2000 will not filter `Encounter` resources for patients born before the year 2000 from the export.

Filtering resources based on the dates associated with a clinical or administrative event, such as exporting encounters that occurred within a certain time period, SHOULD be done using the `_typeFilter` parameter and not the `_since` and `_until` parameters, since the resource modification date used in those filters might not correspond to the date of the clinical or administrative event.

The value of the `_typeFilter` parameter is a FHIR REST API query. Resources with a resource type specified in this query that do not meet the criteria in the search expression in the query SHALL NOT be returned, with the exception of related resources being included by the Data Provider to provide context about the resources being exported (see [processing model](#processing-model)). A Data Consumer MAY repeat the `_typeFilter` parameter multiple times in a kick-off request. When more than one `_typeFilter` parameter is provided with a query for the same resource type, the Data Provider SHALL include resources of that resource type that meet the criteria in any of the parameters (a logical "or").

FHIR [search result parameters](https://www.hl7.org/fhir/search.html#modifyingresults) (such as _sort, _include, and _elements) SHALL NOT be used as `_typeFilter` criteria. Additionally, a query in the `_typeFilter` parameter SHALL have the [search context](https://hl7.org/fhir/search.html#searchcontexts) of a single FHIR Resource Type. The contexts "all resource types" and "a specified compartment" are not allowed. Data Consumers SHOULD consult the Data Provider's CapabilityStatement to identify supported search parameters (see [Data Provider capability documentation](#data-provider-capability-documentation)). Since support for `_typeFilter` is OPTIONAL for a Data Provider, Data Consumers SHOULD be robust to Data Providers that ignore `_typeFilter`.

<div class="stu-note">
<a href="https://hl7.org/fhir/search.html#chaining">Chained parameters</a> used in a <code>typeFilter</code> query are an experimental feature, and when supported by a Data Provider, the set of exported resources resulting from the interactions between the <code>_typeFilter</code> parameter and other kickoff parameters may be surprising. We are soliciting feedback on the use of chained parameters, and depending on the response may consider deprecating this capability in a future version of this IG.
</div>

**Example Request**

The following is an export request for `MedicationRequest` resources, where the Data Consumer would further like to restrict the MedicationRequests to those that are `active`, or else `completed` after July 1, 2018. This can be accomplished with two `_typeFilter` query parameters and an `_type` query parameter:


* `MedicationRequest?status=active`
* `MedicationRequest?status=completed&date=gt2018-07-01T00:00:00Z`

```
$export?
  _type=
    MedicationRequest
  &_typeFilter=
    MedicationRequest%3Fstatus%3Dactive
  &_typeFilter=
    MedicationRequest%3Fstatus%3Dcompleted%26date%3Dgt2018-07-01T00%3A00%3A00Z
```

_Note that newlines and spaces have been added above for clarity, and would not be included in a real request._

##### Processing Model

The following steps outline a model of how a Data Provider might process a bulk export request. The actual operations a Data Provider performs and the order in which they are performed might differ. Additionally, as documented elsewhere in this implementation guide, depending on the values and headers provided, some requests might cause a Data Provider to return an error rather than continuing to process the request.

 <figure>
  {% include processing-model.svg %}
  <figcaption>Model for processing a Bulk Data Export request.</figcaption>
</figure>
<br />
_* In the case of a Group level export, the Data Provider may retain resources modified prior to the `_since` timestamp if the resources belong to the patient compartment of a patient added to the Group after the supplied time and this behavior is documented by the Data Provider._

##### Response - Success

- HTTP Status Code of `202 Accepted`
- `Content-Location` header with the absolute URL of an endpoint for subsequent status requests (polling location)
- When a Prefer header value of `separate-export-status` is provided in the kickoff request and supported by the Data Provider, the response SHALL include the header `Preference-Applied` with values of `respond-async` and `separate-export-status`. These may be provided as comma-delimited values or the header may be repeated for each value.
- Optionally, a FHIR `OperationOutcome` resource in the body in JSON format

##### Response - Error (e.g., unsupported search parameter)

- HTTP Status Code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource in JSON format

If a Data Provider wants to prevent a Data Consumer from beginning a new export before an in-progress export is completed, it SHOULD respond with a `429 Too Many Requests` status and a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header, following the rate-limiting advice for "Bulk Data Status Request" below.

---
#### Bulk Data Status Request

After a Bulk Data request has been started, the Data Consumer MAY poll the status URL provided in the `Content-Location` header according to the [FHIR Asynchronous Bulk Interaction Pattern](async.html).

Data Consumers SHOULD follow an [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff) approach when polling for status. A Data Provider SHOULD supply a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header with a delay time in seconds (e.g., `120` to represent two minutes) or an HTTP-date (e.g., `Fri, 31 Dec 1999 23:59:59 GMT`). When provided, Data Consumers SHOULD use this information to inform the timing of future polling requests. The Data Provider SHOULD keep an accounting of status queries received from a given Data Consumer, and if a Data Consumer is polling too frequently, the Data Provider SHOULD respond with a `429 Too Many Requests` status code in addition to a `Retry-After` header, and optionally a FHIR `OperationOutcome` resource with further explanation. If excessively frequent status queries persist, the Data Provider MAY return a `429 Too Many Requests` status code and terminate the session. Other standard HTTP `4XX` and `5XX` status codes may be used to identify errors as mentioned below.

When requesting status, the Data Consumer SHOULD use an `Accept` header indicating a content type of `application/json`. In the case that errors prevent the export from completing, the Data Provider SHOULD respond with a FHIR `OperationOutcome` resource in JSON format.

##### Endpoint

`GET [polling content location]`

**Responses**

<table class="table">
  <thead>
    <th>Response Type</th>
    <th>Description</th>
    <th>Example Response</th>
  </thead>
  <tbody>
    <tr>
      <td><a href="#response---in-progress-status">In-Progress</a></td>
      <td>Returned by the Data Provider while it is processing the $export request.</td>
      <td>
      Response headers - no <code>Prefer: separate-export-status</code> header on kickoff
      <pre><code>Status: 202 Accepted
X-Progress: "50% complete"
Retry-After: 120</code></pre>
      Response headers - <code>Prefer: separate-export-status</code> header on kickoff
      <pre><code>Status: 200 OK
X-Export-Status: 202 Accepted
X-Progress: "50% complete"
Retry-After: 120</code></pre>
    </td>
    </tr>
    <tr>
      <td><a href="#response---error-status">Error</a></td>
      <td>Returned by the Data Provider if the export operation fails.</td>
      <td>
      Response headers - no <code>Prefer: separate-export-status</code> header on kickoff
      <pre><code>Status: 500 Internal Server Error
Content-Type: application/fhir+json
</code></pre>
      Response headers - <code>Prefer: separate-export-status</code> header on kickoff
      <pre><code>Status: 200 OK
X-Export-Status: 500 Internal Server Error
Content-Type: application/fhir+json
</code></pre>
Body
<div class="language-json">
{% fragment OperationOutcome/export-error-operationoutcome-example JSON ELIDE:language|text %}
</div></td>
    </tr>
    <tr>
      <td><a href="#response---complete-status">Complete</a></td>
      <td>Returned by the Data Provider when the export operation has completed.</td>
      <td>
      Response headers - no <code>Prefer: separate-export-status</code> header on kickoff
      <pre><code>Status: 200 OK
Expires: Mon, 22 Jul 2019 23:59:59 GMT
Content-Type: application/json
</code></pre>
      Response headers - <code>Prefer: separate-export-status</code> header on kickoff
      <pre><code>Status: 200 OK
X-Export-Status: 200 OK
Expires: Mon, 22 Jul 2019 23:59:59 GMT
Content-Type: application/json
</code></pre>
Body
<div class="language-json">
{% include Binary-BulkDataManifestMinimalExample-html.xhtml %}
</div>
</td>
    </tr>
  </tbody>
</table>

##### Response - In-Progress Status

- HTTP Status Code of `202 Accepted` (when a prefer header value of `separate-export-status` was not provided in the kickoff)
- When a Prefer header value of `separate-export-status` was provided in the kickoff and is supported by the Data Provider, HTTP status code of `200 OK` and an `X-Export-Status` header of `202 Accepted`
- Optionally, the Data Provider MAY return an `X-Progress` header with a text description of the status of the request that is less than 100 characters. The format of this description is at the Data Provider's discretion and MAY be a percentage complete value, or MAY be a more general status such as "in progress". The Data Consumer MAY parse the description, display it to the user, or log it.
- When the `allowPartialManifests` kickoff parameter is `true`, the Data Provider MAY return a `Content-Type` header of `application/json` and a body containing an output manifest in the format [described below](#response---output-manifest), populated with a partial set of output files for the export. When provided, a manifest SHALL only contain files that are available for retrieval by the Data Consumer. Once returned, the Data Provider SHALL NOT alter a manifest when it is returned in subsequent requests, with the exception of optionally adding a `link` field pointing to a manifest with additional output files or updating output file URLs that have expired. The output files referenced in the manifest SHALL NOT be altered once they have been included in a manifest that has been returned to a Data Consumer.

##### Response - Error Status

- HTTP status code of `4XX` or `5XX` (when a prefer header value of `separate-export-status` was not provided in the kickoff)
- When a Prefer header value of `separate-export-status` was provided in the kickoff and is supported by the Data Provider, HTTP status code of `200 OK` and an `X-Export-Status` header of `4XX` or `5XX`
- `Content-Type` header of `application/fhir+json` when body is a FHIR `OperationOutcome` resource
- The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible (for example, the infrastructure layer returning the error is not FHIR aware), the Data Provider MAY return an error message in another format and include a corresponding value for the `Content-Type` header.

In the case of a polling failure that does not indicate failure of the export job, a Data Provider SHOULD use a [transient code](https://www.hl7.org/fhir/codesystem-issue-type.html#issue-type-transient) from the [IssueType valueset](https://www.hl7.org/fhir/codesystem-issue-type.html) when populating the FHIR `OperationOutcome` resource's `issue.code` element to indicate to the Data Consumer that it will need retry the request at a later time.

*Note*: Even if some of the requested resources cannot successfully be exported, the overall export operation MAY still succeed. In this case, the `Response.error` array of the completion response body SHALL be populated with one or more files in NDJSON format containing FHIR `OperationOutcome` resources to indicate what went wrong (see below). In the case of a partial success, the Data Provider SHALL use a `200` status code instead of `4XX` or `5XX`. The choice of when to determine that an export job has failed in its entirety (error status) vs. returning a partial success (complete status) is left to the Data Provider.

##### Response - Complete Status

- HTTP status of `200 OK`
- When a Prefer header value of `separate-export-status` was provided in the kickoff and is supported by the Data Provider, an `X-Export-Status` header of `200 OK`
- `Content-Type` header of `application/json`
- The Data Provider SHOULD return an `Expires` header indicating when the files listed will no longer be available for access.
- A body containing the output manifest described below.

##### Response - Output Manifest

The output manifest is a JSON object providing metadata and links to the generated Bulk Data files. The files SHALL be accessible to the Data Consumer at the URLs advertised. These URLs MAY be served by file servers other than the Data Provider's FHIR Resource Server.

{% include export-manifest-fields.md %}

Implementation notes:

- For `transactionTime`, to properly meet the inclusion constraints above, the Data Provider's FHIR server might need to wait for any pending transactions to resolve in its database before starting the export process.
- Error, warning, and information messages related to the export SHOULD be included in `error` and not in `output`. If there are no relevant messages, the Data Provider SHOULD return an empty array. If the request contained invalid or unsupported parameters along with a `Prefer: handling=lenient` header and the Data Provider processed the request, the Data Provider SHOULD include a FHIR `OperationOutcome` resource for each of these parameters.
- When the `_since` timestamp is supplied in the export request, the `deleted` array SHOULD be populated with files containing FHIR transaction Bundles for resources that match the kick-off request criteria but were deleted after the `_since` date. If no resources have been deleted, if `_since` was not supplied, or if the Data Provider has other reasons to avoid exposing these data, the Data Provider MAY omit this key or return an empty array. Resources that appear in `deleted` SHALL NOT also appear in `output`.

<a name="manifest-link"></a>

- When the `allowPartialManifests` kickoff parameter is `true`, the manifest MAY include a `link` array with a single object containing a `relation` field with a value of `next`, and a `url` field pointing to the location of another manifest. All fields in the linked manifest SHALL be populated with the same values as the manifest with the link, apart from the `output`, `deleted`, and `link` arrays.
- If the export has failed or a transient error has occurred, a Data Provider MAY return an error in response to a request for the `next` link, as described in the [Error Status](#response---error-status) section above. For non-transient errors, a Data Consumer MAY process resources that have already been retrieved before re-running the export job or MAY discard them.

Example manifest, `organizeOutputBy` kickoff parameter is not populated:
<div class="language-json">
{% include Binary-BulkDataManifestByTypeExample-html.xhtml %}
</div>
[View Example](Binary-BulkDataManifestByTypeExample.html)

<a name="organize-output-by-manifest-example" />

Example manifest, `organizeOutputBy` kickoff parameter is `Patient`, and `allowPartialManifests` kickoff parameter is `true`:

<div class="language-json">
{% include Binary-BulkDataManifestOrganizedByPatientExample-html.xhtml %}
</div>

[View Example](Binary-BulkDataManifestOrganizedByPatientExample.html)

Example deleted resource bundle (represents one line in an output file):

<div class="language-json">
{% fragment Bundle/deleted-resource-transaction-bundle-example JSON ELIDE:language %}
</div>

[View Example](Bundle-deleted-resource-transaction-bundle-example.html)


---
{% include async-delete-request.md %}

---
{% include async-output-file-request.md %}

{% include async-output-file-organization.md %}

{% include async-attachments.md %}

### Data Provider Capability Documentation

This implementation guide is structured to support a wide variety of Bulk Data Export use cases and Data Provider architectures. To provide clarity to developers on which capabilities are implemented by a particular Data Provider, Data Providers SHALL ensure that their CapabilityStatement accurately reflects the implemented Bulk Data Operations. Additionally, the Data Provider's CapabilityStatement SHOULD list the resource types available for export in the `rest.resource` element, and SHOULD list the search parameters that can be used in the `_typeFilter` parameter in `rest.resource.searchParam` elements.

Data Providers SHOULD indicate resource types and search parameters that are accessible through the REST API, but not available using the Bulk Export operation, with one or more extensions that have a URL of `http://hl7.org/fhir/uv/bulkdata/Extension/operation-not-supported` and a `valueCanonical` with the canonical URL for the [OperationDefinition](artifacts.html#behavior-operation-definitions) of the bulk operation that is not supported. Alternatively, the extension may be populated with the canonical URL for the FHIR Bulk Data Access Implementation Guide [CapabilityStatement](CapabilityStatement-bulk-data.html) when none of the bulk operations are supported.

Data Providers SHOULD also ensure that their documentation addresses the topics below. Future versions of this IG may define a computable format for this information as well.

- Does the Data Provider restrict responses to a specific profile like the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/) or the [Blue Button Implementation Guide](http://hl7.org/fhir/us/carin-bb/)?
- What approach does the Data Provider take to divide data sets into multiple files (e.g., single file per single resource type, limit file size to 100MB, limit number of resources per file to 100,000)?
- Are additional supporting resources such as `Practitioner` or `Organization` included in the export and under what circumstances?
- Does the Data Provider support system-wide (or all-patients, or Group-level) export? What parameters are supported for each request type? Note that this SHOULD also be captured in the Data Provider's CapabilityStatement.
- What `outputFormat` values does this Data Provider support?
- In the case of a Group level export, does the `_since` parameter return additional resources modified prior to the supplied time if the resources belong to the patient compartment of a patient added to the Group after the supplied time?
- What `includeAssociatedData` values does this Data Provider support?
