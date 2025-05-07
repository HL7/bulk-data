### Audience and Scope

This implementation guide is intended to be used by developers of backend services (clients) and FHIR Resource Servers (e.g., EHR systems, data warehouses, and other clinical and administrative systems) that aim to interoperate by sharing large FHIR datasets. The guide defines the application programming interfaces (APIs) through which an authenticated and authorized client may request a Bulk Data Export from a server, receive status information regarding progress in the generation of the requested files, and retrieve these files.  It also includes recommendations regarding the FHIR resources that might be exposed through the export interface.  

The scope of this document does NOT include:

* A legal framework for sharing data between partners, such as Business Associate Agreements, Service Level Agreements, and Data Use Agreements, though these may be required for some use cases.
* Real-time data exchange
* Data transformations that may be required by the client
* Patient matching (although identifiers may be included in the exported FHIR resources)
* Management of FHIR groups (although some Bulk Data operations require a FHIR Group id, this guide does not specify how Group resources are created and maintained within a system)

### Underlying Standards

* [HL7 FHIR](https://www.hl7.org/fhir/)
* [Newline-delimited JSON](https://github.com/ndjson/ndjson-spec)
* [RFC5246, Transport Layer Security (TLS) Protocol Version 1.2](https://tools.ietf.org/html/rfc5246)
* [RFC6749, The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
* [RFC6750, The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750)
* [RFC7159, The JavaScript Object Notation (JSON) Data Interchange Format](https://tools.ietf.org/html/rfc7159)
* [RFC7240, Prefer Header for HTTP](https://tools.ietf.org/html/rfc7240)

### Terminology

This profile inherits terminology from the standards referenced above.
The key words "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in [RFC2119](https://tools.ietf.org/html/rfc2119).

### Privacy and Security Considerations

All exchanges described herein between a client and a server SHALL be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://tools.ietf.org/html/rfc5246) or a more recent version of TLS.  Use of mutual TLS is OPTIONAL.  

With each of the requests described herein, implementers SHOULD implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html). When SMART Backend Services Authorization is used, Bulk Data Status Request and Bulk Data Output File Requests with `requiresAccessToken=true` SHALL be protected the same way the Bulk Data Kick-off Request, including an access token with scopes that cover all resources being exported. A server MAY additionally restrict Bulk Data Status Request and Bulk Data Output File Requests by limiting them to the client that originated the export. Implementations MAY include endpoints that use authorization schemes other than OAuth 2.0, such as mutual-TLS or signed URLs.     

This implementation guide does not address protection of a server from potential compromise. An adversary who successfully captures administrative rights to the server will have full control over that server and can use those rights to undermine the server's security protections. In the Bulk Data Export workflow, the file server will be a particularly attractive target, as it holds highly sensitive and valued PHI. An adversary who successfully takes control of a file server may choose to continue to deliver files in response to client requests, so that neither the client nor the FHIR server is aware of the take-over. Meanwhile, the adversary is able to put the PHI to use for its own malicious purposes.   

Healthcare organizations have an imperative to protect PHI persisted in file servers in both cloud and data-center environments. A range of existing and emerging approaches can be used to accomplish this, not all of which would be visible at the API level. This specification does not dictate a particular approach at this time, though it does support the use of an `Expires` header to limit the time period a file will be available for client download (removal of the file from the server is left up to the server implementer). A server SHOULD NOT delete files from a Bulk Data response that a client is actively in the process of downloading regardless of the pre-specified expiration time.

Data access control obligations can be met with a combination of in-band restrictions (e.g., OAuth scopes), and out-of-band restrictions, where the server limits the data returned to a specific client in accordance with local considerations (e.g.  policies or regulations). The FHIR server SHALL limit the data returned to only those FHIR resources for which the client is authorized. Implementers SHOULD incorporate technology that preserves and respects an individual's wishes to share their data with desired privacy protections. For example, some clients are authorized to access sensitive mental health information and some aren't; this authorization is defined out-of-band, but when a client requests a full data set, filtering is automatically applied by the server, restricting the data that the client receives.

Bulk Data Export can be a resource-intensive operation. Server developers SHOULD consider and mitigate the risk of intentional or inadvertent denial-of-service attacks though the details are beyond the scope of this specification. For example, transactional systems may wish to provide Bulk Data access to a read-only mirror of the database or may distribute processing over time to avoid loads that could impact clinical operations.

### Bulk Data Export Operation Request Flow

This implementation guide builds on the [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html), and in some places may extend the pattern.

#### Roles

There are two primary roles involved in a Bulk Data transaction:

  1. **Bulk Data Provider** - consists of:

      a. **FHIR Authorization Server** - server that issues access tokens in response to valid token requests from client.

      b. **FHIR Resource Server** - server that accepts kick-off request and provides job status and completion manifest.

      c. **Output File Server** - server that returns FHIR Bulk Data files and attachments in response to urls in the completion manifest. This may be built into the FHIR Server, or may be independently hosted.

  2. **Bulk Data Client** - system that requests and receives access tokens and Bulk Data files

#### Sequence Overview 

 <figure>
  {% include bulk-flow.svg %}
  <figcaption>Diagram showing an overview of the Bulk Data Export operation request flow</figcaption>
</figure>

#### Bulk Data Kick-off Request

The Bulk Data Export Operation initiates the asynchronous generation of a requested export dataset - whether that be data for all patients, data for a subset (defined group) of patients, or all FHIR data in the server.

As discussed in See [Privacy and Security Considerations](#privacy-and-security-considerations) above, a server SHALL limit the data returned to only those FHIR resources for which the client is authorized.

The Resource FHIR server SHALL support invocation of this operation using the [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html). A server SHALL support GET requests and MAY support POST requests that supply parameters using the FHIR [Parameters Resource](https://www.hl7.org/fhir/parameters.html).

A client MAY repeat kick-off parameters that accept comma delimited values multiple times in a kick-off request. The server SHALL treat the values provided as if they were comma delimited values within a single instance of the parameter. Note that we will be soliciting feedback on the use of comma delimited values within parameters, and depending on the response may consider deprecating this input approach in favor of repeating parameters in a future version of this IG.

For Patient-level requests and Group-level requests associated with groups of patients, the [Patient Compartment](https://www.hl7.org/fhir/compartmentdefinition-patient.html) SHOULD be used as a point of reference for recommended resources to be returned and, where applicable, Patient resources SHOULD be returned. Other resources outside of the patient compartment that are helpful in interpreting the patient data (such as Organization and Practitioner) MAY also be returned.

Binary Resources whose content is associated with an individual patient SHALL be serialized as DocumentReference Resources with the `content.attachment` element populated as described in the [Attachments](#attachments) section below. Binary Resources not associated with an individual patient MAY be included in a System Level export.

References in the resources returned MAY be relative URLs with the format <code>&lt;resource type&gt;/&lt;id&gt;</code>, or MAY be absolute URLs with the same structure rooted in the base URL for the server from which the export was performed. 

##### Endpoint - All Patients

`[fhir base]/Patient/$export`

[View table of parameters for Patient Export](OperationDefinition-patient-export.html)

FHIR Operation to obtain a detailed set of FHIR resources of diverse resource types pertaining to all patients.

##### Endpoint - Group of Patients

`[fhir base]/Group/[id]/$export`

[View table of parameters for Group Export](OperationDefinition-group-export.html)

FHIR Operation to obtain a detailed set of FHIR resources of diverse resource types pertaining to all members of a specified [Group](https://www.hl7.org/fhir/group.html).

If a FHIR server supports Group-level data export, it SHOULD support reading and searching for `Group` resource. This enables clients to discover available groups based on stable characteristics such as `Group.identifier`.

Note: How these Groups are defined is specific to each FHIR system's implementation. For example, a payer may send a healthcare institution a roster file that can be imported into their EHR to create or update a FHIR group. Group membership could be based upon explicit attributes of the patient, such as age, sex or a particular condition such as PTSD or Chronic Opioid use, or on more complex attributes, such as a recent inpatient discharge or membership in the population used to calculate a quality measure. FHIR-based group management is out of scope for the current version of this implementation guide.

##### Endpoint - System Level Export

`[fhir base]/$export`

[View table of parameters for Export](OperationDefinition-export.html)

Export data from a FHIR server, whether or not it is associated with a patient. This supports use cases like backing up a server, or exporting terminology data by restricting the resources returned using the `_type` parameter.

##### Headers

- `Accept` (string)

  Specifies the format of the optional FHIR `OperationOutcome` resource response to the kick-off request. Currently, only `application/fhir+json` is supported. A client SHOULD provide this header. If omitted, the server MAY return an error or MAY process the request as if `application/fhir+json` was supplied.

- `Prefer` (string)

  Specifies whether the response is immediate or asynchronous. Currently, only a value of <a href="https://datatracker.ietf.org/doc/html/rfc7240#section-4.1"><code>respond-async</code></a> is supported. A client SHOULD provide this header. If omitted, the server MAY return an error or MAY process the request as if respond-async was supplied.

##### Query Parameters

<table class="table">
  <thead>
    <th>Query Parameter</th>
    <th>Optionality for Server</th>
    <th>Optionality for Client</th>
    <th>Cardinality</th>
    <th>Type</th>
    <th>Description</th>
  </thead>
  <tbody>
    <tr>
      <td><code>_outputFormat</code></td>
      <td><span class="label label-info">required</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..1</td>
      <td>String</td>
      <td>The format for the requested Bulk Data files to be generated as per <a href="http://hl7.org/fhir/R4/async.html">FHIR Asynchronous Request Pattern</a>. Defaults to <code>application/fhir+ndjson</code>. The server SHALL support <a href="http://ndjson.org">Newline Delimited JSON</a>, but MAY choose to support additional output formats. The server SHALL accept the full content type of <code>application/fhir+ndjson</code> as well as the abbreviated representations <code>application/ndjson</code> and <code>ndjson</code>.</td>
    </tr>
    <tr>
      <td><code>_since</code></td>
      <td><span class="label label-info">required</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..1</td>
      <td>FHIR instant</td>
      <td>Resources will be included in the response if their state has changed after the supplied time (e.g., if <code>Resource.meta.lastUpdated</code> is later than the supplied <code>_since</code> time). In the case of a Group level export, the server MAY return additional resources modified prior to the supplied time if the resources belong to the patient compartment of a patient added to the Group after the supplied time (this behavior SHOULD be clearly documented  by the server). The server MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the server does not maintain a last updated time, the server MAY include these resources in a response irrespective of the <code>_since</code> value supplied by a client.</td>
    </tr>
    <tr>
      <td><code>_until</code></td>
      <td><span class="label label-info">optional</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..1</td>
      <td>FHIR instant</td>
      <td>Resources will be included in the response if their state has changed before the supplied time (e.g., if <code>Resource.meta.lastUpdated</code> is earlier than the supplied <code>_until</code> time). The server MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the server does not maintain a last updated time, the server MAY include these resources in a response irrespective of the <code>_until</code> value supplied by a client.</td>
    </tr>
    <tr>
      <td><code>_type</code></td>
      <td><span class="label label-info">optional</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..*</td>
      <td>string of comma-delimited FHIR resource types</td>
      <td>The response SHALL be filtered to only include resources of the specified resource types(s).<br /><br />
      If this parameter is omitted, the server SHALL return all supported resources within the scope of the client authorization, though implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the <a href="http://www.hl7.org/fhir/us/core/">US Core Implementation Guide</a>. For Patient- and Group-level requests, the <a href='https://www.hl7.org/fhir/compartmentdefinition-patient.html'>Patient Compartment</a> SHOULD be used as a point of reference for recommended resources to be returned. However, other resources outside of the Patient Compartment that are referenced by the resources being returned and would be helpful in interpreting the patient data MAY also be returned (such as Organization and Practitioner). When this behavior is supported, a server SHOULD document this support (for example, as narrative text, or by including a <a href="https://www.hl7.org/fhir/graphdefinition.html">GraphDefinition Resource</a>).<br /><br />
      A server that is unable to support <code>_type</code> SHOULD return an error and FHIR <code>OperationOutcome</code> resource so the client can re-submit a request omitting the <code>_type</code> parameter. If the client explicitly asks for export of resources that the Bulk Data server doesn't support, or asks for only resource types that are outside the Patient Compartment, the server SHOULD return details via a FHIR <code>OperationOutcome</code> resource in an error response to the request. When a <code>Prefer: handling=lenient</code> header is included in the request, the server MAY process the request instead of returning an error.<br /><br />
      For example <code>_type=Observation</code> could be used to filter a given export response to return only FHIR <code>Observation</code> resources.</td>
    </tr>
    <tr>
      <td><code>_elements</code></td>
      <td><span class="label label-info">optional, experimental</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..*</td>
      <td>string of comma-delimited FHIR Elements</td>
      <td>When provided, the server SHOULD omit unlisted, non-mandatory elements from the resources returned. Elements SHOULD be of the form <code>[resource type].[element name]</code> (e.g., <code>Patient.id</code>) or <code>[element name]</code> (e.g., <code>id</code>) and only root elements in a resource are permitted. If the resource type is omitted, the element SHOULD be returned for all resources in the response where it is applicable.<br /><br />
      A server is not obliged to return just the requested elements. A server SHOULD always return mandatory elements whether they are requested or not. A server SHOULD mark the resources with the tag SUBSETTED to ensure that the incomplete resource is not actually used to overwrite a complete resource.<br/><br/>
      A server that is unable to support <code>_elements</code> SHOULD return an error and FHIR <code>OperationOutcome</code> resource so the client can re-submit a request omitting the <code>_elements</code> parameter. When a <code>Prefer: handling=lenient</code> header is included in the request, the server MAY process the request instead of returning an error.
      </td>
    </tr>
    <tr>
      <td><code>patient</code><br/>(POST requests only)</td>
      <td><span class="label label-info">optional</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..*</td>
      <td>FHIR Reference</td>
      <td>Not applicable to system level export requests. When provided, the server SHALL NOT return resources in the patient compartments belonging to patients outside of this list. If a client requests patients who are not present on the server (or in the case of a group level export, who are not members of the group), the server SHOULD return details via a FHIR <code>OperationOutcome</code> resource in an error response to the request.<br /><br />
      A server that is unable to support <code>patient</code> SHOULD return an error and FHIR <code>OperationOutcome</code> resource so the client can re-submit a request omitting the <code>patient</code> parameter. When a <code>Prefer: handling=lenient</code> header is included in the request, the server MAY process the request instead of returning an error.
      </td>
    </tr>
    <tr>
      <td><code>includeAssociatedData</code><br/></td>
      <td><span class="label label-info">optional, experimental</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..*</td>
      <td>string of comma delimited values</td>
      <td>When provided, a server with support for the parameter and requested values SHALL return or omit a pre-defined set of FHIR resources associated with the request.<br /><br />
      A server that is unable to support the requested <code>includeAssociatedData</code> values SHOULD return an error and FHIR <code>OperationOutcome</code> resource so the client can re-submit a request that omits those values (for example, if a server does not retain provenance data). When a <code>Prefer: handling=lenient</code> header is included in the request, the server MAY process the request instead of returning an error.<br /><br />
      A client MAY include one or more of the following values. If multiple conflicting values are included, the server SHALL apply the least restrictive value (value that will return the largest dataset).
      <ul>
        <li><code>LatestProvenanceResources</code>: Export will include the most recent Provenance resources associated with each of the non-provenance resources being returned. Other Provenance resources will not be returned.</li>
        <li><code>RelevantProvenanceResources</code>: Export will include all Provenance resources associated with each of the non-provenance resources being returned.</li>
        <li><code>_[custom value]</code>: A server MAY define and support custom values that are prefixed with an underscore (e.g., <code>_myCustomPreset</code>).</li>
      </ul>
      </td>
    </tr>
    <tr>
      <td><code>_typeFilter</code><br/></td>
      <td><span class="label label-info">optional</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..*</td>
      <td>string of a FHIR REST API query</td>
      <td>When provided, a server with support for the parameter and the requested search parameters SHALL filter the data in the response for resource types referenced in the typeFilter expression to only include resources that meet the specified criteria. FHIR search result parameters such as <code>_include</code> and <code>_sort</code> SHALL NOT be used. <a href="#_typefilter-query-parameter">See details below</a>.<br /><br />
      A server unable to support the requested <code>_typeFilter</code> queries SHOULD return an error and FHIR <code>OperationOutcome</code> resource so the client can re-submit a request that omits those queries. When a <code>Prefer: handling=lenient</code> header is included in the request, the server MAY process the request instead of returning an error.
      </td>
    </tr>
    <tr>
      <td><code>organizeOutputBy</code><br/></td>
      <td><span class="label label-info">optional</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..1</td>
      <td><a href="https://hl7.org/fhir/valueset-resource-types.html">string of a FHIR resource type</a></td>
      <td>When provided, a server with support for the parameter SHALL organize the resources in output files by instances of the specified resource type, including a header for each resource of the type specified in the parameter, followed by the resource and resources in the output that contain references to that resource. When omitted, servers SHALL organize each output file with resources of only single type. <a href="#bulk-data-output-file-organization">See details below</a>.<br /><br />
      A server unable to structure output by the requested <code>organizeOutputBy</code> resource SHOULD return an error and FHIR <code>OperationOutcome</code> resource. When a <code>Prefer: handling=lenient</code> header is included in the request, the server MAY process the request instead of returning an error.
      </td>
    </tr>
    <tr>
      <td><code>allowPartialManifests</code><br/></td>
      <td><span class="label label-info">optional</span></td>
      <td><span class="label label-info">optional</span></td>
      <td>0..1</td>
      <td>boolean</td>
      <td>When provided, a server with support for the parameter MAY distribute the bulk data output files among multiple manifests, providing links for clients to page through the manifests (<a href="#manifest-link">see details below)</a>. Prior to all of the files in the export being available, the server MAY return a manifest with files that are available along with a <code>202 Accepted</code> HTTP response status, and subsequently update the manifest with a paging link to a new manifest when additional files are ready for download (<a href="#response---in-progress-status">see details below</a>).
      </td>
    </tr>
  </tbody>
</table>

*Note*: Implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/). If the client explicitly asks for export of resources that the Bulk Data server doesn't support, the server SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request.

If an <code>includeAssociatedValue</code> value relevant to provenance is not specified, or if this parameter is not supported by a server, the server SHALL include all available Provenance resources whose `Provenance.target` is a resource in the Patient compartment in a patient level export request, and all available Provenance resources in a system level export request unless a specific resource set is specified using the <code>_type</code> parameter and this set does not include Provenance.

##### Group Membership Request Pattern

To obtain new and updated resources for patients in a group, as well as all data for patients who have joined the group since a prior query, a client can use following pattern:

- Initial Query (e.g., on January 1, 2020):

  - Client submits a group export request:

    `[baseurl]/Group/[id]/$export`

  - Client retrieves response data
  - Client retains a list of the patient ids returned
  - Client retains the transactionTime value from the response

- Subsequent Queries (e.g., on February 1, 2020):
  - Client submits a group export request to obtain a patient list:

    `[baseurl]/Group/[id]/$export?_type=Patient&_elements=id`

  - Client retains a list of patient ids returned
  - Client compares response to patient ids from first query request and identifies new patient ids
  - Client submits a group export request via POST for patients who are new members of the group: 

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
    
  - Client submits a group export request for updated group data: 

    `[baseurl]/Group/[id]/$export?_since=[initial transaction time]`
    
    Note that data returned from this request may overlap with that returned from the prior step.

  - Client retains the transactionTime value from the response.

##### `_typeFilter` Query Parameter

The `_typeFilter` parameter enables finer-grained filtering out of resources in the bulk data export response that would have otherwise been returned. For example, a client may want to retrieve only active prescriptions rather than all prescriptions and only laboratory observations rather than all observations. When using `_typeFilter`, each resource type is filtered independently. For example, filtering `Patient` resources to people born after the year 2000 will not filter `Encounter` resources for patients born before the year 2000 from the export.

The value of the `_typeFilter` parameter is a FHIR REST API query. Resources with a resource type specified in this query that do not meet the criteria in the search expression in the query SHALL NOT be returned, with the exception of related resources being included by a server to provide context about the resources being exported (see [processing model](#processing-model)). A client MAY repeat the `_typeFilter` parameter multiple times in a kick-off request. When more than one `_typeFilter` parameter is provided with a query for the same resource type, the server SHALL include resources of that resource type that meet the criteria in any of the parameters (a logical "or").  

FHIR [search result parameters](https://www.hl7.org/fhir/search.html#modifyingresults) (such as _sort, _include, and _elements) SHALL NOT be used as `_typeFilter` criteria. Additionally, a query in the `_typeFilter` parameter SHALL have the [search context](https://hl7.org/fhir/search.html#searchcontexts) of a single FHIR Resource Type. The contexts "all resource types" and "a specified compartment" are not allowed. Clients should consult the server's capability statement to identify supported search parameters (see [server capability documentation](#server-capability-documentation)). Since support for `_typeFilter` is OPTIONAL for a FHIR server, clients SHOULD be robust to servers that ignore `_typeFilter`.

<div class="stu-note">
<a href="https://hl7.org/fhir/search.html#chaining">Chained parameters</a> used in a <code>typeFilter</code> query are an experimental feature, and when supported by a server, the set of exported resources resulting from the interactions between the <code>_typeFilter</code> parameter and other kickoff parameters may be surprising. We are soliciting feedback on the use of chained parameters, and depending on the response may consider deprecating this capability in a future version of this IG.
</div>

**Example Request**

The following is an export request for `MedicationRequest` resources, where the client would further like to restrict the MedicationRequests to those that are `active`, or else `completed` after July 1, 2018. This can be accomplished with two `_typeFilter` query parameters and an `_type ` query parameter:


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

The following steps outline a logical model of how a server should process a bulk export request. The actual operations a server performs and the order in which they're performed may differ. Additionally, as documented elsewhere in this implementation guide, depending on the values and headers provided, some requests may cause a server to return an error rather than continuing to process the request.

 <figure>
  {% include processing-model.svg %}
  <figcaption>Diagram outlining a logical model of how a server should process a bulk export request.</figcaption>
</figure>
<br />
_* In the case of a Group level export, the server may retain resources modified prior to _since timestamp if the resources belong to the patient compartment of a patient added to the Group after the supplied time and this behavior is documented by the server._

##### Response - Success

- HTTP Status Code of `202 Accepted`
- `Content-Location` header with the absolute URL of an endpoint for subsequent status requests (polling location)
- Optionally, a FHIR `OperationOutcome` resource in the body in JSON format

##### Response - Error (e.g., unsupported search parameter)

- HTTP Status Code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource in JSON format

If a server wants to prevent a client from beginning a new export before an in-progress export is completed, it SHOULD respond with a `429 Too Many Requests` status and a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header, following the rate-limiting advice for "Bulk Data Status Request" below.

---
#### Bulk Data Delete Request

After a Bulk Data request has been started, a client MAY send a DELETE request to the URL provided in the `Content-Location` header to cancel the request as described in the [FHIR Asynchronous Request Pattern](https://www.hl7.org/fhir/R4/async.html).  If the request has been completed, a server MAY use the request as a signal that a client is done retrieving files and that it is safe for the sever to remove those from storage. Following the delete request, when subsequent requests are made to the polling location, the server SHALL return a `404 Not Found` error and an associated FHIR `OperationOutcome` in JSON format.

##### Endpoint

`DELETE [polling content location]`

##### Response - Success

- HTTP Status Code of `202 Accepted`
- Optionally a FHIR `OperationOutcome` resource in the body in JSON format

##### Response - Error Status

- HTTP status code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource in JSON format

---
#### Bulk Data Status Request

After a Bulk Data request has been started, the client MAY poll the status URL provided in the `Content-Location` header as described in the [FHIR Asynchronous Request Pattern](https://www.hl7.org/fhir/R4/async.html).

Clients SHOULD follow an [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff) approach when polling for status. A server SHOULD supply a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header with a with a delay time in seconds (e.g., `120` to represent two minutes) or a http-date (e.g., `Fri, 31 Dec 1999 23:59:59 GMT`). When provided, clients SHOULD use this information to inform the timing of future polling requests. The server SHOULD keep an accounting of status queries received from a given client, and if a client is polling too frequently, the server SHOULD respond with a `429 Too Many Requests` status code in addition to a `Retry-After` header, and optionally a FHIR `OperationOutcome` resource with further explanation.  If excessively frequent status queries persist, the server MAY return a `429 Too Many Requests` status code and terminate the session. Other standard HTTP `4XX` as well as `5XX` status codes may be used to identify errors as mentioned.

When requesting status, the client SHOULD use an `Accept` header indicating a content type of  `application/json`. In the case that errors prevent the export from completing, the server SHOULD respond with a FHIR `OperationOutcome` resource in JSON format.

##### Endpoint

`GET [polling content location]`

**Responses**

<table class="table">
  <thead>
    <th>Response Type</th>
    <th>Description</th>
    <th>Example Response Headers + Body</th>
  </thead>
  <tbody>
    <tr>
      <td><a href="#response---in-progress-status">In-Progress</a></td>
      <td>Returned by the server while it is processing the $export request.</td>
      <td><pre><code>Status: 202 Accepted
X-Progress: “50% complete”
Retry-After: 120</code></pre></td>
    </tr>
    <tr>
      <td><a href="#response---error-status-1">Error</a></td>
      <td>Returned by the server if the export operation fails.</td>
      <td><pre><code>Status: 500 Internal Server Error
Content-Type: application/fhir+json

{
&nbsp;"resourceType": "OperationOutcome",
&nbsp;"id": "1",
&nbsp;"issue": [
&nbsp;&nbsp;{
&nbsp;&nbsp;&nbsp;"severity": "error",
&nbsp;&nbsp;&nbsp;"code": "processing",
&nbsp;&nbsp;&nbsp;"details": {
&nbsp;&nbsp;&nbsp;&nbsp;"text": "An internal timeout has occurred"
&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;}
&nbsp;]
}</code></pre></td>
    </tr>
    <tr>
      <td><a href="#response---complete-status">Complete</a></td>
      <td>Returned by the server when the export operation has completed.</td>
      <td><pre><code>Status: 200 OK
Expires: Mon, 22 Jul 2019 23:59:59 GMT
Content-Type: application/json

{
&nbsp;"transactionTime": "2021-01-01T00:00:00Z",
&nbsp;"request" : "https://example.com/fhir/Patient/$export?_type=Patient,Observation",
&nbsp;"requiresAccessToken" : true,
&nbsp;"output" : [{
&nbsp;&nbsp;"type" : "Patient",
&nbsp;&nbsp;"url" : "https://example.com/output/patient_file_1.ndjson"
&nbsp;},{
&nbsp;&nbsp;"type" : "Patient",
&nbsp;&nbsp;"url" : "https://example.com/output/observation_file_1.ndjson"
&nbsp;},{
&nbsp;&nbsp;"type" : "Observation",
&nbsp;&nbsp;"url" : "https://example.com/output/observation_file_2.ndjson"
&nbsp;}],
&nbsp;"deleted" : [{
&nbsp;&nbsp;"type" : "Bundle",
&nbsp;&nbsp;"url" : "https://example.com/output/del_file_1.ndjson"
&nbsp;}],
&nbsp;"error" : [{
&nbsp;&nbsp;"type" : "OperationOutcome",
&nbsp;&nbsp;"url" : "https://example.com/output/err_file_1.ndjson"
&nbsp;}],
&nbsp;"extension":{"https://example.com/extra-property": true}
}</code></pre></td>
    </tr>
  </tbody>
</table>

##### Response - In-Progress Status

- HTTP Status Code of `202 Accepted`
- Optionally, the server MAY return an `X-Progress` header with a text description of the status of the request that is less than 100 characters. The format of this description is at the server's discretion and MAY be a percentage complete value, or MAY be a more general status such as "in progress". The client MAY parse the description, display it to the user, or log it.
- When the `allowPartialManifests` kickoff parameter is `true`, the server MAY return a `Content-Type` header of `application/json` and a body containing an output manifest in the format [described below](#response---output-manifest), populated with a partial set of output files for the export. When provided, a manifest SHALL only contain files that are available for retrieval by the client. Once returned, the server SHALL NOT alter a manifest when it is returned in subsequent requests, with the exception of optionally adding a `link` field pointing to a manifest with additional output files or updating output file URLs that have expired. The output files referenced in the manifest SHALL NOT be altered once they have been included in a manifest that has been returned to a client.

##### Response - Error Status

- HTTP status code of `4XX` or `5XX`
- `Content-Type` header of `application/fhir+json` when body is a FHIR `OperationOutcome` resource
- The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible (for example, the infrastructure layer returning the error is not FHIR aware), the server MAY return an error message in another format and include a corresponding value for the `Content-Type` header.

In the case of a polling failure that does not indicate failure of the export job, a server SHOULD use a [transient code](https://www.hl7.org/fhir/codesystem-issue-type.html#issue-type-transient) from the [IssueType valueset](https://www.hl7.org/fhir/codesystem-issue-type.html) when populating the FHIR `OperationOutcome` resource's `issue.code` element to indicate to the client that it should retry the request at a later time.

*Note*: Even if some of the requested resources cannot successfully be exported, the overall export operation MAY still succeed. In this case, the `Response.error` array of the completion response body SHALL be populated with one or more files in ndjson format containing FHIR `OperationOutcome` resources to indicate what went wrong (see below). In the case of a partial success, the server SHALL use a `200` status code instead of `4XX` or `5XX`.  The choice of when to determine that an export job has failed in its entirety (error status) vs. returning a partial success (complete status) is left up to the server implementer.

##### Response - Complete Status

- HTTP status of `200 OK`
- `Content-Type` header of `application/json`
- The server SHOULD return an `Expires` header indicating when the files listed will no longer be available for access.
- A body containing the output manifest described below.

##### Response - Output Manifest

The output manifest is a JSON object providing metadata and links to the generated Bulk Data files. The files SHALL be accessible to the client at the URLs advertised. These URLs MAY be served by file servers other than a FHIR-specific server.

<table class="table">
  <thead>
    <th>Field</th>
    <th>Optionality</th>
    <th>Type</th>
    <th>Description</th>
  </thead>
  <tbody>
    <tr>
      <td><code>transactionTime</code></td>
      <td><span class="label label-success">required</span></td>
      <td>FHIR instant</td>
      <td>Indicates the server's time when the query is run. The response SHOULD NOT include any resources modified after this instant, and SHALL include any matching resources modified up to and including this instant.
      <br/>
      <br/>
      Note: To properly meet these constraints, a FHIR server might need to wait for any pending transactions to resolve in its database before starting the export process.
      </td>
    </tr>
    <tr>
      <td><code>request</code></td>
      <td><span class="label label-success">required</span></td>
      <td>String</td>
      <td>The full URL of the original Bulk Data kick-off request. In the case of a POST request, this URL will not include the request parameters. Note: this field may be removed in a future version of this IG.</td>
    </tr>
    <tr>
      <td><code>requiresAccessToken</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Boolean</td>
      <td>Indicates whether downloading the generated files requires the same authorization mechanism as the <code>$export</code> operation itself.
      <br/>
      <br/>
      Value SHALL be <code>true</code> if both the file server and the FHIR API server control access using OAuth 2.0 bearer tokens. Value MAY be <code>false</code> for file servers that use access-control schemes other than OAuth 2.0, such as downloads from Amazon S3 bucket URLs or verifiable file servers within an organization's firewall.
      </td>
    </tr>
    <tr>
      <td><code>outputOrganizedBy</code></td>
      <td><span class="label label-success">required</span> when <code>organizeOutputBy</code> was populated</td>
      <td>String</td>
      <td>The organizeOutputBy value from the Bulk Data kick-off request when populated and supported.</td>
    </tr>
    <tr>
      <td><code>output</code></td>
      <td><span class="label label-success">required</span></td>
      <td>JSON array</td>
      <td>An array of file items with one entry for each generated file. If no resources are returned from the kick-off request, the server SHOULD return an empty array.
        <br/>
        <br/>
        The <code>url</code> field SHALL be populated for each output item. When a resource type is not specified in the <code>organizeOutputBy</code> kick-off parameter, the <code>type</code> field SHALL also be populated for each item. When a resource type is specified in the <code>organizeOutputBy</code> kick-off parameter and resources related to a resource of this type continue into another output file, the <code>continuesInFile</code> field SHALL be populated with the URL of that output file.
        <br/>
        <br/>
        <ul>
          <li><code>type</code> - the FHIR resource type that is contained in the file.<br/></li>    
          <li><code>url</code> - the absolute path to the file. The format of the file SHOULD reflect that requested in the <code>_outputFormat</code> parameter of the initial kick-off request.<br/></li>
          <li><code>continuesInFile</code> - url of the output file when resources associated with a FHIR resource of the type specified in the <code>organizeOutputBy</code> kick-off parameter in this file continue into another file. <a href="#bulk-data-output-file-organization">See details below</a>.<br/></li>
          <li><code>count</code> (optional) - the number of resources in the file, represented as a JSON number.<br/></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td><code>deleted</code></td>
      <td><span class="label label-success">optional</span></td>
      <td>JSON array</td>
      <td>An array of deleted file items following the same structure as the <code>output</code> array.
      <br/>
      <br/>
        The ability to convey deleted resources is important in cases when a server may have previously exported data and wishes to indicate that these data should be removed from downstream systems. When a <code>_since</code> timestamp is supplied in the export request, this array SHOULD be populated with output files containing FHIR Transaction Bundles that indicate which FHIR resources match the kick-off request criteria, but have been deleted subsequent to the <code>_since</code> date. If no resources have been deleted, or the <code>_since</code> parameter was not supplied, or the server has other reasons to avoid exposing these data, the server MAY omit this key or MAY return an empty array. Resources that appear in the 'deleted' section of an export manifest SHALL NOT appear in the 'output' section of the manifest.
      <br/>
      <br/>
        Each line in the output file SHALL contain a FHIR Bundle with a type of <code>transaction</code> which SHALL contain one or more entry items that reflect a deleted resource. In each entry, the <code>request.url</code> and <code>request.method</code> elements SHALL be populated. The <code>request.method</code> element SHALL be set to <code>DELETE</code>.
      <br/>
      <br/>
        Example deleted resource bundle (represents one line in output file):
      <pre><code>{
&nbsp;"resourceType": "Bundle",
&nbsp;"id": "bundle-transaction",
&nbsp;"meta": {"lastUpdated: "2020-04-27T02:56:00Z},
&nbsp;"type": "transaction",
&nbsp;"entry":[{
&nbsp;&nbsp;"request": {"method": "DELETE", "url": "Patient/123"}
&nbsp;&nbsp;...
&nbsp;}]
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><code>error</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Array</td>
      <td>Array of message file items following the same structure as the <code>output</code> array.
      <br/>
      <br/>
        Error, warning, and information messages related to the export SHOULD be included here (not in output). If there are no relevant messages, the server SHOULD return an empty array. Only the FHIR <code>OperationOutcome</code> resource type is currently supported, so the server SHALL generate files in the same format as Bulk Data output files that contain FHIR <code>OperationOutcome</code> resources.<br/><br/>
        If the request contained invalid or unsupported parameters along with a <code>Prefer: handling=lenient</code> header and the server processed the request, the server SHOULD include a FHIR <code>OperationOutcome</code> resource for each of these parameters.
        <br/><br/>Note: this field may be renamed in a future version of this IG to reflect the inclusion of FHIR <code>OperationOutcome</code> resources with severity levels other than error.
      </td>
    </tr>
    <tr>
      <td><code id="manifest-link">link</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>JSON array</td>
      <td>
        When the <code>allowPartialManifests</code> kickoff parameter is <code>true</code>, the manifest MAY include a <code>link</code> array with a single object containing a <code>relation</code> field with a value of <code>next</code>, and a <code>url</code> field pointing to the location of another manifest. All fields in the linked manifest SHALL be populated with the same values as the manifest with the link, apart from the <code>output</code>, <code>deleted</code> and <code>link</code> arrays.
        <br/><br/>
        In response to a request to a <code>next link</code>, a server MAY return an error as described <a href="#response---error-status-1">Error Status</a> section above. For non-transient errors, a client MAY process resources that have already retrieved prior to re-running the export job or MAY discard them.
      </td>
    </tr>
    <tr>
      <td><code>extension</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>JSON object</td>
      <td>To support extensions, this implementation guide reserves the name <code>extension</code> and will never define a field with that name, allowing server implementations to use it to provide custom behavior and information. For example, a server may choose to provide a custom extension that contains a decryption key for encrypted ndjson files. The value of an extension element SHALL be a pre-coordinated JSON object.
      <br/>
      <br/>
      Note: In addition to extensions being supported on the root object level, extensions may also be included within the fields above (e.g., in the 'output' object).
      </td>
    </tr>
  </tbody>
</table>

Example manifest, `organizeOutputBy` kickoff parameter is not populated:

```json
  {
    "transactionTime": "2021-01-01T00:00:00Z",
    "request" : "https://example.com/fhir/Patient/$export?_type=Patient,Observation",
    "requiresAccessToken" : true,
    "output" : [{
      "type" : "Patient",
      "url" : "https://example.com/output/patient_file_1.ndjson"
    },{
      "type" : "Observation",
      "url" : "https://example.com/output/observation_file_1.ndjson"
    },{
      "type" : "Observation",
      "url" : "https://example.com/output/observation_file_2.ndjson"
    }],
    "deleted": [{
      "type" : "Bundle",
      "url" : "https://example.com/output/del_file_1.ndjson"      
    }],
    "error" : [{
      "type" : "OperationOutcome",
      "url" : "https://example.com/output/err_file_1.ndjson"
    }],
    "extension":{"https://example.com/extra-property": true}
  }
```

Example manifest, `organizeOutputBy` kickoff parameter is `Patient`, and `allowPartialManifests` kickoff parameter is `true`:

```json
  {
    "transactionTime": "2021-01-01T00:00:00Z",
    "request" : "https://example.com/fhir/Patient/$export?_type=Patient,Observation",
    "requiresAccessToken" : true,
    "outputOrganizedBy": "Patient",
    "output" : [{
      "url" : "https://example.com/output/file_1.ndjson"
    },{
      "url" : "https://example.com/output/file_2.ndjson",
      "continuesInFile": "https://example.com/output/file_3.ndjson"
    },{
      "url" : "https://example.com/output/file_3.ndjson"
    }],
    "deleted": [{
      "type" : "Bundle",
      "url" : "https://example.com/output/del_file_1.ndjson"      
    }],
    "error" : [{
      "type" : "OperationOutcome",
      "url" : "https://example.com/output/err_file_1.ndjson"
    }],
    "extension":{"https://example.com/extra-property": true},
    "link": [{
      "relation": "next",
      "url": "https://example.com/output/manifest-2.json"
    }]
  }
```

---
#### Bulk Data Output File Organization

Output files may be organized by resource type, or by instances of a resource type specified in the `organizeOutputBy` kickoff parameter.

When the `organizeOutputBy` kickoff parameter is not populated, each output file SHALL contain resources of only one type, and a server MAY create more than one file for each resource type returned. The number of resources contained in a file MAY vary between servers and files. 

When the `organizeOutputBy` kickoff parameter is populated with a resource type, the output files SHALL be populated with blocks consisting of a header `Parameters` resource containing a parameter named `header` with a reference to a resource of the type in the kickoff parameter, followed by the resource referenced in this header and resources that reference the resource referenced in the header (together a "resource block"). Each output file MAY contain multiple resource blocks and, when possible, a single resource's block SHOULD NOT be split across files. If a resource block does span more than one file, the header SHALL be repeated at the start of each file where the block continues, and the association between these files SHALL be documented in the manifest using the `continuesInFile` field in the relevant `output` array items. 

Resources that would otherwise be included in the export, but do not have references to the resource type specified in the `organizeOutputBy` parameter, MAY be included in a resource blocks that contain resources they reference, MAY be repeated in every resource block, or MAY be omitted from the export.  

<div class="stu-note">
When the <code>organizeOutputBy</code> parameter is set <code>Patient</code>, servers SHOULD use the <a href="https://www.hl7.org/fhir/compartmentdefinition-patient.html">Patient Compartment Definition</a> to determine a base set of related resources to include in a resource block, though other resources may also be included.  

For other resource types, we are soliciting feedback on the best approach for documenting the set of resources in a resource block. Implementation Guides MAY reference a <a hre="https://www.hl7.org/fhir/compartmentdefinition.html">Compartment Definition</a>, populate a <a href="https://www.hl7.org/fhir/graphdefinition.html">GraphDefinition Resource</a>, include narrative text, or use another approach.
</div>

Example header for `Patient` resource:
```json
{
  "resourceType" : "Parameters",
  "parameter" : [{
    "name": "header",
    "valueReference": {"reference": "Patient/123"}
  }]
}
```

#### Bulk Data Output File Request

Using the URLs supplied by the FHIR server in the manifest, a client MAY download the generated Bulk Data files (one or more per resource type) within the time period specified in the `Expires` header (if present). A client MAY re-fetch the output manifest if output links have expired, and a server MAY provide updated links and/or an updated timestamp in the `Expires` header in the response. 

As long as a server is following relevant security guidance, it MAY generate output manifests where the `requiresAccessToken` field is `true` or `false`; this applies even for servers available on the public internet.

If the `requiresAccessToken` field in the manifest is set to `true`, the request SHALL include a valid access token.  See [Privacy and Security Considerations](#privacy-and-security-considerations) above.  

If the `requiresAccessToken` field is set to `false` and no additional authorization-related extensions are present in the manifest's output entry, then the output URLs SHALL be dereferenceable directly (a "capability URL"), and SHALL follow expiration timing requirement that have been documented for bearer tokens in SMART Backend Services. A client SHALL NOT provide a SMART Backend Services access token when dereferencing an output URL where `requiresAccessToken` is `false`.

The exported data SHALL include only the most recent version of any exported resources unless the client explicitly requests different behavior in a fashion supported by the server (e.g.,  via a new query parameter yet to be defined). Inclusion of the `Resource.meta` information in the resources is at the discretion of the server (as it is for all FHIR interactions).

A client SHOULD provide an `Accept-Encoding` header when requesting output files and SHOULD include `gzip` compression as one of the encoding options in the header. A server SHALL provide output files as uncompressed, with `gzip` compression, or with another compression format from the `Accept-Encoding` header. When compression is used, a server SHALL communicate this to the client by including a `Content-Encoding` header in the response. A client SHALL accept files that are uncompressed or encoded with `gzip` compression, and MAY accept files encoded with other compression formats.

Example NDJSON output file:
```
{"id":"5c41cecf-cf81-434f-9da7-e24e5a99dbc2","name":[{"given":["Brenda"],"family":["Jackson"]}],"gender":"female","birthDate":"1956-10-14T00:00:00.000Z","resourceType":"Patient"}
{"id":"3fabcb98-0995-447d-a03f-314d202b32f4","name":[{"given":["Bram"],"family":["Sandeep"]}],"gender":"male","birthDate":"1994-11-01T00:00:00.000Z","resourceType":"Patient"}
{"id":"945e5c7f-504b-43bd-9562-a2ef82c244b2","name":[{"given":["Sandy"],"family":["Hamlin"]}],"gender":"female","birthDate":"1988-01-24T00:00:00.000Z","resourceType":"Patient"}
```

##### Endpoint

`GET [url from status request output field]`

##### Headers

- `Accept` (optional, defaults to `application/fhir+ndjson`)

Specifies the format of the file being requested.

##### Response - Success

- HTTP status of `200 OK`
- `Content-Type` header that matches the file format being delivered.  For files in ndjson format, SHALL be `application/fhir+ndjson`
- Body of FHIR resources in newline delimited json - [ndjson](http://ndjson.org/) or other requested format

##### Response - Error

- HTTP Status Code of `4XX` or `5XX`

##### Attachments

If resources in an output file contain elements of the type `Attachment`, the server SHOULD populate the `Attachment.contentType` code as well as either the `data` element or the `url` element. If the data element is not populated and the url element is populated, the url element SHALL be an absolute url that can be de-referenced to the attachment's content.

When the `url` element is populated with an absolute URL and the `requiresAccessToken` field in the Complete Status body is set to `true`, the url location must be accessible by a client with a valid access token, and SHALL NOT require the use of additional authentication credentials.  When the `url` element is populated and the `requiresAccessToken` field in the Complete Status body is set to `false`, the url location must be accessible by a client without an access token. 

Note that if a server copies files to the Bulk Data output endpoint or proxies requests to facilitate access from this endpoint, it may need to modify the `Attachment.url` element when generating the Bulk Data output files.

### Server Capability Documentation

This implementation guide is structured to support a wide variety of Bulk Data Export use cases and server architectures. To provide clarity to developers on which capabilities are implemented in a particular server, server providers SHALL ensure that their Capability Statement accurately reflects the implemented Bulk Data Operations. Additionally, the server's Capability Statement SHOULD list the resource types available for export in the `rest.resource` element, and SHOULD list the search parameters that can be used in the `_typeFilter` parameter in `rest.resource.searchParam` elements. 

Servers SHOULD indicate resource types and search parameters that are accessible on the server with the REST API, but not available using the Bulk Export operation, with one or more extensions that have a URL of `http://hl7.org/fhir/uv/bulkdata/Extension/operation-not-supported` and a `valueCanonical` with the canonical URL for the [OperationDefinition](artifacts.html#behavior-operation-definitions) of the bulk operation that is not supported. Alternatively, the extension may be populated with the canonical URL for the FHIR Bulk Data Access Implementation Guide [CapabilityStatement](artifacts.html#behavior-capability-statements) when none of the bulk operations are supported.

Server providers SHOULD also ensure that their documentation addresses the topics below. Future versions of this IG may define a computable format for this information as well.

- Does the server restrict responses to a specific profile like the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/) or the [Blue Button Implementation Guide](http://hl7.org/fhir/us/carin-bb/)?
- What approach does the server take to divide datasets into multiple files (e.g., single file per single resource type, limit file size to 100MB, limit number of resources per file to 100,000)?
- Are additional supporting resources such as `Practitioner` or `Organization` included in the export and under what circumstances?
- Does the server support system-wide (or all-patients, or Group-level) export? What parameters are supported for each request type? Note that this should also be captured in the server's CapabilityStatement.
- What `outputFormat` values does this server support?
- In the case of a Group level export, does the `_since` parameter return additional resources modified prior to the supplied time if the resources belong to the patient compartment of a patient added to the Group after the supplied time?
- What `includeAssociatedData` values does this server support?
