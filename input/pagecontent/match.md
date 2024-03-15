### Audience and Scope

This implementation guide is intended to be used by the developers of **bulk match clients** - systems that wish to determine the FHIR Patient resource ids of a set of patients in a FHIR server by transmitting demographic information, and developers of **bulk match providers** - FHIR servers that use demographic information to find patients and respond with sets of matching Patient resources. 

The guide defines the application programming interfaces (APIs) through which an authenticated and authorized client may request a "bulk match" from a server, receive status information regarding progress in the identification of the requested patients, and retrieve files with the matches. Clients can then use the returned ids in other API requests such as a [FHIR Bulk Data Export](./export) to retrieve additional data on these patients.

The focus of this guide is on standards based communication of match requests and responses. Match providers may use any applicable matching algorithm to determine the most appropriate patient matches, proxy match requests to a single patient match operation on another FHIR server, act as a facade that layers FHIR APIs and serialization on top of a non-FHIR matching system, or even queue requests for manual matching within a user interface.

A legal framework for sharing data between partners, such as Business Associate Agreements, Service Level Agreements, and Data Use Agreements, is not in scope for this guide, though these may be required for some use cases. The Bulk Match operation does not specify a minimum set of information that must be provided when asking for a match operation to be performed, but implementations and Implementation Guides that reference this one may require a set of minimum information, which should be declared in their definition of the Bulk Match operation by specifying a profile on the resource parameter to indicate which properties are required in the search.

Example use cases:
* Payer organization wants to learn which of the older members in a plan have not received a flu shot based on data in a state immunization registry and needs to match patients from its member database to those in the state immunization information system.
* Provider organization wants to update their records of the vaccination status of a high risk cohort to support panel management activities based on data in a state immunization registry, and needs to match patients from its EHR system to those in the state immunization information system.
* Provider organization wants to know which of the patients in its population are members of a risk based contract at a payer organization and needs to match patients from its EHR system to those in the payer member database.

### Underlying Standards

* [HL7 FHIR](https://www.hl7.org/fhir/)
  * [Patient Resource](https://www.hl7.org/fhir/patient.html)
  * [Patient Match Operation](http://hl7.org/fhir/patient-operation-match.html)
  * [FHIR Asynchronous Bulk Data Request Pattern](https://hl7.org/fhir/async-bulk.html)
* [SMART Backend Services Authorization Profile](http://www.hl7.org/fhir/smart-app-launch/backend-services.html)

### Terminology

This profile inherits terminology from the standards referenced above.
The key words "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in [RFC2119](https://tools.ietf.org/html/rfc2119).

### Privacy and Security Considerations

All exchanges described herein between a client and a server SHALL be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://tools.ietf.org/html/rfc5246) or a more recent version of TLS.  Use of mutual TLS is OPTIONAL.  

With each of the requests described herein, implementers SHOULD implement OAuth 2.0 access management in accordance with the [SMART Backend Services Authorization Profile](authorization.html). When SMART Backend Services Authorization is used, Bulk Match Status Request and Bulk Match Output File Requests with `requiresAccessToken=true` SHALL be protected the same way the Bulk Match Kick-off Request, including an access token with scopes that cover all resources being exported. A server MAY additionally restrict Bulk Match Status Request and Bulk Match Output File Requests by limiting them to the client that originated the export. Implementations MAY include endpoints that use authorization schemes other than OAuth 2.0, such as mutual-TLS or signed URLs.     

This implementation guide does not address protection of a server from potential compromise. An adversary who successfully captures administrative rights to the server will have full control over that server and can use those rights to undermine the server's security protections. In the Bulk Match workflow, the file server will be a particularly attractive target, as it holds highly sensitive and valued identify information. An adversary who successfully takes control of a file server may choose to continue to deliver files in response to client requests, so that neither the client nor the FHIR server is aware of the take-over. Meanwhile, the adversary is able to put the data to use for its own malicious purposes.   

Organizations have an imperative to protect data persisted in file servers in both cloud and data-center environments. A range of existing and emerging approaches can be used to accomplish this, not all of which would be visible at the API level. This specification does not dictate a particular approach at this time, though it does support the use of an `Expires` header to limit the time period a file will be available for client download (removal of the file from the server is left up to the server implementer). A server SHOULD NOT delete files from a Bulk Match response that a client is actively in the process of downloading regardless of the pre-specified expiration time.

Data access control obligations can be met with a combination of in-band restrictions (e.g., OAuth scopes), and out-of-band restrictions, where the server limits the data returned to a specific client in accordance with local considerations (e.g.  policies or regulations). The FHIR server SHALL limit the data returned to only those FHIR resources for which the client is authorized. Implementers SHOULD incorporate technology that preserves and respects an individual's wishes to share their data with desired privacy protections.

Bulk Match can be a resource-intensive operation. Server developers SHOULD consider and mitigate the risk of intentional or inadvertent denial-of-service attacks though the details are beyond the scope of this specification. For example, transactional systems may wish to provide Bulk Match access to a read-only mirror of the database or may distribute processing over time to avoid loads that could impact operations.

#### Roles

There are two primary roles involved in a Bulk Match transaction:

  1. **Bulk Match Provider** - consists of:

      a. **FHIR Authorization Server** - server that issues access tokens in response to valid token requests from client.

      b. **FHIR Resource Server** - server that accepts kick-off request and provides job status and completion manifest.

      c. **Output File Server** - server that returns FHIR Bulk Data files in response to urls in the completion manifest. This may be built into the FHIR Server, or may be independently hosted.

  2. **Bulk Match Client** - system that requests and receives access tokens and Bulk Data files

#### Sequence Overview 

 <figure>
  {% include bulk-match-flow.svg %}
  <figcaption>Diagram showing an overview of the Bulk Match operation request flow</figcaption>
</figure>


#### Bulk Match Kick-off Request

The Resource FHIR server SHALL support invocation of the Bulk Match operation using the [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html). A server SHALL support POST requests that supply parameters using the FHIR [Parameters Resource](https://www.hl7.org/fhir/parameters.html).

##### Endpoint

`[fhir base]/Patient/$bulk-match`

##### Parameters

Parameters are based on those in the [Single Patient Match Operation](http://build.fhir.org/patient-operation-match.html), with the `resource` parameter adjusted to permit a cardinality of `[1..*]` and the addition of the `_outputFormat` parameter. 

The patient resources submitted to the operation do not need to be complete. Individual systems and use case specific implementation guides MAY require data elements and/or specific identifier types be populated. Note that the client SHALL provide an `id` element for each Patient resource that's unique to a patient in the source system, since this `id` will be returned as part of the response to enable tying the match bundles to patients in the request.

The server MAY document a limit on the number of bytes or instances of the `resource` parameter in a kickoff request. For requests larger than this limit, a client can break the request into smaller requests and submit them serially. See the [Response - Error](#response---error) section below for more details.

<style>
	td {
		border-top: 1px solid #dddddd;
		padding: 8px;
    	line-height: 1.428571429;
    	vertical-align: top;
	}
</style>

| Name | Cardinality | Type | Documentation |
| --- |--- | --- | --- |
| resource | 1..* | [Resource](https://hl7.org/fhir/resource.html) | [Patient](https://www.hl7.org/fhir/patient.html) resource with the entire set of patient details to match against. |
|onlySingleMatch | 0..1 | boolean | If there are multiple potential matches, the server should identify the single most appropriate match that should be used with future interactions with the server (for example, as part of a subsequent create interaction).|
|onlyCertainMatches | 0..1 | boolean | If there are multiple potential matches, the server should be certain that each of the records are for the same patient. This could happen if the records are duplicates, are the same person for the purpose of data segregation, or other reasons. When false, the server may return multiple results with each result graded accordingly.|
|count| 0..1 | integer | The maximum number of records to return per resource. If no value is provided, the server may decide how many matches to return. Note that clients should be careful when using this, as it may prevent probable - and valid - matches from being returned. |
| _outputFormat | 0..1 | string | The format for the Bulk Data files to be generated as per the [FHIR Asynchronous Bulk Request Pattern](http://hl7.org/fhir/async-bulk.html). Defaults to `application/fhir+ndjson`. The server SHALL support [Newline Delimited JSON](http://ndjson.org), but MAY support additional output formats. The server SHALL accept the full content type of `application/fhir+ndjson` as well as the abbreviated representations `application/ndjson` and `ndjson` |

[OperationDefinition](OperationDefinition-bulk-match.html)


##### Headers

- `Accept` (string)

  Specifies the format of the optional FHIR `OperationOutcome` resource response to the kick-off request. Currently, only `application/fhir+json` is supported. A client SHOULD provide this header. If omitted, the server MAY return an error or MAY process the request as if `application/fhir+json` was supplied.

- `Prefer` (string)

  Specifies whether the response is immediate or asynchronous. Currently, only a value of <a href="https://datatracker.ietf.org/doc/html/rfc7240#section-4.1"><code>respond-async</code></a> is supported. A client SHOULD provide this header. If omitted, the server MAY return an error or MAY process the request as if respond-async was supplied.

##### Response - Success

- HTTP Status Code of `202 Accepted`
- `Content-Location` header with the absolute URL of an endpoint for subsequent status requests (polling location)
- Optionally, a FHIR `OperationOutcome` resource in the body in JSON format

##### Response - Error

- HTTP Status Code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource in JSON format
- The server MAY reject a bulk match request if number of bytes or instances of the resource parameter is too large by returning a `413 Content Too Large` header. A client SHOULD respond by breaking the request into smaller requests and submitting them serially. These limits SHOULD be described in the server documentation.
- If a server wants to prevent a client from beginning a new match request before an in-progress match request is completed, it SHOULD respond with a `429 Too Many Requests` status and a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header, following the rate-limiting advice for "Bulk Match Status Request" below.

---
#### Bulk Match Delete Request

After a Bulk Match request has been started, a client MAY send a DELETE request to the URL provided in the `Content-Location` header to cancel the request as described in the [FHIR Asynchronous Bulk Data Request Pattern](https://www.hl7.org/fhir/R4/async-bulk.html). If the request has been completed, a server MAY use the request as a signal that a client is done retrieving files and that it is safe for the sever to remove those from storage. Following the delete request, when subsequent requests are made to the polling location, the server SHALL return a `404 Not Found` error and an associated FHIR `OperationOutcome` in JSON format.

##### Endpoint

`DELETE [polling content location]`

##### Response - Success

- HTTP Status Code of `202 Accepted`
- Optionally a FHIR `OperationOutcome` resource in the body in JSON format

##### Response - Error Status

- HTTP status code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource in JSON format

---
#### Bulk Match Status Request

After a Bulk Match request has been started, the client MAY poll the status URL provided in the `Content-Location` header as described in the [FHIR Asynchronous Bulk Data Request Pattern](https://www.hl7.org/fhir/R4/async-bulk.html).

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
      <td>Returned by the server while it is processing the Bulk Match request.</td>
      <td><pre><code>Status: 202 Accepted
X-Progress: “50% complete”
Retry-After: 120</code></pre></td>
    </tr>
    <tr>
      <td><a href="#response---error-status-1">Error</a></td>
      <td>Returned by the server if the Bulk Match operation fails.</td>
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
      <td>Returned by the server when the Bulk Match operation has completed.</td>
      <td><pre><code>Status: 200 OK
Expires: Mon, 22 Jul 2019 23:59:59 GMT
Content-Type: application/json

{
&nbsp;"transactionTime": "2021-01-01T00:00:00Z",
&nbsp;"request" : "https://example.com/fhir/Patient/$bulk-match",
&nbsp;"requiresAccessToken" : true,
&nbsp;"output" : [{
&nbsp;&nbsp;"type" : "Bundle",
&nbsp;&nbsp;"url" : "https://example.com/output/match_file_1.ndjson"
&nbsp;},{
&nbsp;&nbsp;"type" : "Bundle",
&nbsp;&nbsp;"url" : "https://example.com/output/match_file_2.ndjson"
&nbsp;}],
&nbsp;"error" : [],
&nbsp;"extension":{"https://example.com/extra-property": true}
}</code></pre></td>
    </tr>
  </tbody>
</table>


##### Response - In-Progress Status

- HTTP Status Code of `202 Accepted`
- Optionally, the server MAY return an `X-Progress` header with a text description of the status of the request that is less than 100 characters. The format of this description is at the server's discretion and MAY be a percentage complete value, or MAY be a more general status such as "in progress". The client MAY parse the description, display it to the user, or log it.

##### Response - Error Status

- HTTP status code of `4XX` or `5XX`
- `Content-Type` header of `application/fhir+json` when body is a FHIR `OperationOutcome` resource
- The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible (for example, the infrastructure layer returning the error is not FHIR aware), the server MAY return an error message in another format and include a corresponding value for the `Content-Type` header.

In the case of a polling failure that does not indicate failure of the export job, a server SHOULD use a [transient code](https://www.hl7.org/fhir/codesystem-issue-type.html#issue-type-transient) from the [IssueType valueset](https://www.hl7.org/fhir/codesystem-issue-type.html) when populating the FHIR `OperationOutcome` resource's `issue.code` element to indicate to the client that it should retry the request at a later time.

*Note*: Even if some of the requested resources cannot successfully be matched, the overall match operation MAY still succeed. In this case, FHIR `OperationOutcome` resources should be included in the searchset Bundle resources being returned to indicate what went wrong (see [Match Bundles](#match-bundles) below). In the case of a partial success, the server SHALL use a `200` status code instead of `4XX` or `5XX`.  The choice of when to determine that a job has failed in its entirety (error status) vs. returning a partial success (complete status) is left up to the server implementer.

##### Response - Complete Status

- HTTP status of `200 OK`
- `Content-Type` header of `application/json`
- The server SHOULD return an `Expires` header indicating when the files listed will no longer be available for access.
- A body containing a JSON object providing metadata, and links to the generated Bulk Data files.  The files SHALL be accessible to the client at the URLs advertised. These URLs MAY be served by file servers other than a FHIR-specific server.

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
      <td>The full URL of the original Bulk Match kick-off request. This URL will not include the request parameters and may be removed in a future version of this IG.</td>
    </tr>
    <tr>
      <td><code>requiresAccessToken</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Boolean</td>
      <td>Indicates whether downloading the generated files requires the same authorization mechanism as the <code>$bulk-match</code> operation itself.
      <br/>
      <br/>
      Value SHALL be <code>true</code> if both the file server and the FHIR API server control access using OAuth 2.0 bearer tokens. Value MAY be <code>false</code> for file servers that use access-control schemes other than OAuth 2.0, such as downloads from Amazon S3 bucket URLs or verifiable file servers within an organization's firewall.
      </td>
    </tr>
    <tr>
      <td><code>output</code></td>
      <td><span class="label label-success">required</span></td>
      <td>JSON array</td>
      <td>An array of file items with one entry for each generated file. If no resources are returned, the server SHOULD return an empty array.
      <br/>
      <br/>
        Each file item SHALL contain the following fields:
        <br/>
        <br/>
          - <code>type</code> - fixed value of "Bundle"
          <br/>
          <br/>
          - <code>url</code> - the absolute path to the file. The format of the file SHOULD reflect that requested in the <code>_outputFormat</code> parameter of the initial kick-off request.
          <br/>
          <br/>
        Each file item MAY optionally contain the following field:
        <br/>
        <br/>
          - <code>count</code> - the number of resources in the file, represented as a JSON number.
		<br/>
		<br/>
		The number of FHIR searchset Bundle resources per file MAY vary between servers.
      </td>
    </tr>
    <tr>
      <td><code>error</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Array</td>
      <td>Empty array. To align with the single patient match operation, error, warning, and information messages related to matches SHOULD be included in the match bundles in files in the output array.</td>
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

---
#### Bulk Match Output File Request

Using the URLs supplied by the FHIR server in the Complete Status response body, a client MAY download the generated Bulk Data files within the time period specified in the `Expires` header (if present). 

If the `requiresAccessToken` field in the Complete Status body is set to `true`, the request SHALL include a valid access token.  Regardless, a server SHALL limit the data returned to only those FHIR resources for which the client is authorized. See [Privacy and Security Considerations](#privacy-and-security-considerations) above.  

The exported data SHALL include only the most recent version of any exported resources unless the client explicitly requests different behavior in a fashion supported by the server (e.g.,  via a new query parameter yet to be defined). Inclusion of the `Resource.meta` information in the resources is at the discretion of the server (as it is for all FHIR interactions).

##### Match Bundles

The `output` array SHALL contain zero or more FHIR Bundle Resources with a `type` of `searchset`. An output in the default `ndjson` format SHALL contain one FHIR Bundle on each line.

Each Bundle SHALL contain zero or more matching results for a `Patient` resource submitted in the kickoff request and MAY contain one or more `OperationOutcome` resources with an errors, warnings, or information related to the match. For example, if the match was unsuccessful, then an `OperationOutcome` may be returned along with a `BadRequest` status Code (e.g. insufficient properties in patient fragment). Patient records SHALL be ordered from most likely to least likely. If there are no patient matches, the bundle SHALL contain either an empty search set, or one or more `OperationOutcome` resources with further advice regarding patient selection.

Bundles SHALL include an extension to the `meta` element with a url of `http://hl7.org/fhir/uv/bulkdata/OperationDefinition/match-resource`, and a `valueReference` populated with a reference to an input Patient resource in the match request.

All patient records in the Bundle SHALL have a search score from 0 to 1, where 1 is the most certain match, along with an extension `http://hl7.org/fhir/StructureDefinition/match-grade` that indicates the server's position on the match quality with a value from the [match grade valueset](https://hl7.org/fhir/extensions/ValueSet-match-grade.html).

[Match Bundle Profile](StructureDefinition-bulk-match-bundle.html)

Example (note that line breaks and spacing should not be present when the bundle is included in an ndjson file):
```
"resourceType": "Bundle",
"type": "searchset",
"meta": {
  "extension": [{
    "url": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/match-resource",
    "valueReference": {
		//this is the id from the kickoff request
		"reference": "Patient/1234" 
	}
  }]
}
"entry": [{
  "fullUrl": "http://server/path/Patient/5678",
  "resource": {
    "resourceType": "Patient",
    "id": "5678", //this is the id from the responding system
    ... snip ...
  },
  "search": {
    "extension": [{
      "url": "http://hl7.org/fhir/StructureDefinition/match-grade",
      "valueCode": "certain"
    }],
    "mode": "match",
    "score": 0.9
  }
}]
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