### Audience and Scope

This implementation guide is intended to be used by developers of backend services (clients) and data providers (servers) that aim to interoperate by sharing large FHIR datasets. The guide defines the application programming interfaces (APIs) through which a client may retrieve pre-generated FHIR bulk-data files from a server. These files may be provided at an open endpoint, or may require the client to authenticate and authorize access to retrieve the data.

In contrast to the FHIR bulk data [export operation ($export)](./export.html), the publish operation ($bulk-publish) returns a static manifest and set of pre-generated bulk data files and does not provide a mechanism for a client to retrieve a filtered subset of the available data. Systems that dynamically manage information about individual patients should use the export operation and not the bulk-publish operation. Systems that return infrequently updated reference information may wish to use the bulk-publish operation instead of the export operation to reduce the complexity and cost involved in hosting and providing this information. 

Expected use cases include publication of provider directories by payor organizations and healthcare organizations, and publication of formulary information by payors.


### Underlying Standards

* [HL7 FHIR](https://www.hl7.org/fhir/)
* [Newline-delimited JSON](http://ndjson.org)
* [RFC5246, Transport Layer Security (TLS) Protocol Version 1.2](https://tools.ietf.org/html/rfc5246)
* [RFC6749, The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
* [RFC6750, The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750)
* [RFC7159, The JavaScript Object Notation (JSON) Data Interchange Format](https://tools.ietf.org/html/rfc7159)

### Terminology

This profile inherits terminology from the standards referenced above.
The key words "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in RFC2119.

### Security Considerations

All exchanges described herein between a client and a server SHALL be secured using [Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)](https://tools.ietf.org/html/rfc5246) or a more recent version of TLS.  Use of mutual TLS is OPTIONAL. With each of the requests described herein, implementers MAY implement OAuth 2.0 access management in accordance with the [SMART Backend Services: Authorization Guide](authorization.html).

### Request Flow

#### Manifest Request

Request for fully static or periodically updated dataset in FHIR format. 

GET `[fhir base]/$bulk-publish`

- A client MAY include an `_since` parameter with a value that is a [FHIR instant](https://www.hl7.org/fhir/datatypes.html#instant). If this parameter is provided, the server MAY restrict the FHIR resources included in the response to only those that have been created or modified after the supplied time (e.g., `Resource.meta.lastUpdated` is later).


##### Response - Error

- HTTP status code of ```4XX``` or ```5XX```
- `Content-Type` header of `application/fhir+json`
- The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible (for example, the infrastructure layer returning the error is not FHIR aware), the server MAY return an error message in another format and include a corresponding value for the `Content-Type` header.


##### Response - Manifest

- HTTP status of ```200 OK```
- ```Content-Type``` header of ```application/json```
- The server MAY return an ```Expires``` header indicating when the files listed will no longer be available for access.
- A body containing a JSON object providing metadata, and links to the generated bulk data files.  The files SHALL be accessible to the client at the URLs advertised. These URLs MAY be served by file servers other than a FHIR-specific server.

Required Fields:

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
      <td>Indicates the server's time when the bulk data files included in the manifest were generated. The response SHOULD NOT include any resources modified after this instant, and SHALL include any matching resources modified up to and including this instant.
      <br/>
      <br/>
      Note: To properly meet these constraints, a FHIR Server might need to wait for any pending transactions to resolve in its database before generating the export files.
      </td>
    </tr>
    <tr>
      <td><code>request</code></td>
      <td><span class="label label-success">required</span></td>
      <td>String</td>
      <td>The full URL of the original manifest request.</td>
    </tr>
    <tr>
      <td><code>requiresAccessToken</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Boolean</td>
      <td>Indicates whether downloading the generated files requires a bearer access token
      <br/>
      <br/>
      Value SHALL be <code>true</code> if both the file server and the FHIR API server control access using OAuth 2.0 bearer tokens.
      </td>
    </tr>
    <tr>
      <td><code>output</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Array</td>
      <td>An array of file items with one entry for each generated file. If no resources are returned from the kick-off request, the server SHOULD return an empty array.
      <br/>
      <br/>
        Each file item SHALL contain the following fields:
        <br/>
        <br/>
          - <code>type</code> - the FHIR resource type that is contained in the file.
          <br/>
          <br/>
            Each file SHALL contain resources of only one type, but a server MAY create more than one file for each resource type returned. The number of resources contained in a file MAY vary between servers. If no data are found for a resource, the server SHOULD NOT return an output item for that resource in the response. These rules apply only to top-level resources within the response; as always in FHIR, any resource MAY have a "contained" array that includes referenced resources of other types.
            <br/>
            <br/>
          - <code>url</code> - the path to the file.
		    <br/>
            <br/>
          - <code>extension.format</code> - MIME type of the output file. All data must be made available as `application/fhir+ndjson`, but servers MAY also provide the data in other formats. Servers SHOULD include this extension for files in ndjson format, but SHALL include it for files in other formats. If more than one format is supported, clients should filter the file items in the output array and only retrieve those in the desired format. The number of files may differ by format (eg. each ndjson format file may contain fewer resources than a binary file format of the same size, resulting in fewer entries in the output array).
          <br/>
          <br/>
        Each file item MAY optionally contain the following field:
        <br/>
        <br/>
          - <code>count</code> - the number of resources in the file, represented as a JSON number.
      </td>
    </tr>
    <tr>
      <td><code>error</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Array</td>
      <td>Array of message file items following the same structure as the <code>output</code> array.
      <br/>
      <br/>
        Error, warning, and information messages related to the export should be included here (not in output). If there are no relevant messages, the server SHOULD return an empty array. Only the <code>OperationOutcome</code> resource type is currently supported, so a server SHALL generate files in the same format as bulk data output files that contain <code>OperationOutcome</code> resources.
        <br/><br/>Note: this field may be renamed in a future version of this IG to reflect the inclusion of <code>OperationOutcome</code> resources with severity levels other than error.
      </td>
    </tr>
    <tr>
      <td><code>extension</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>JSON Object</td>
      <td>To support extensions, this implementation guide reserves the name <code>extension</code> and will never define a field with that name, allowing server implementations to use it to provide custom behavior and information. For example, a server may choose to provide a custom extension that contains a decryption key for encrypted ndjson files. The value of an extension element SHALL be a pre-coordinated JSON object.
      <br/>
      <br/>
      Note: In addition to extensions being supported on the root object level, extensions may also be included within the fields above (e.g., in the 'output' object).
      </td>
    </tr>
  </tbody>
</table>

Example response body:

```json
  {
    "transactionTime": "2021-01-01T00:00:00Z",
    "request" : "https://example.com/pd/$bulk-publish",
    "requiresAccessToken" : true,
    "output" : [{
	  "type" : "Practitioner",
	  "url" : "https://example.com/pd/practitioner_file_1.ndjson",
	  "extension" : {
		  "format" : "application/fhir+ndjson"
	  }
    },{
      "type" : "Practitioner",
	  "url" : "https://example.com/pd/practitioner_file_2.ndjson",
	  "extension" : {
        "format" : "application/fhir+ndjson"
	  }
    },{
      "type" : "Organization",
	  "url" : "https://example.com/pd/organization_file_1.ndjson",
	   "extension" : {
	      "format" : "application/fhir+ndjson"
		}
	},{
      "type" : "Location",
	  "url" : "https://example.com/pd/location_file_1.ndjson",
	   "extension" : {
	      "format" : "application/fhir+ndjson"
	    }
    }],
    "error" : []
  }
```

---
#### Output File Request

Using the URLs supplied by the FHIR server in the Complete Status response body, a client MAY download the generated bulk data files (one or more per resource type) within the time period specified in the ```Expires``` header (if present). If the ```requiresAccessToken``` field in the Complete Status body is set to ```true```, the request SHALL include a valid access token.  See the Security Considerations section above.  

The exported data SHALL include only the most recent version of any exported resources unless the client explicitly requests different behavior in a fashion supported by the server (e.g.  via a new query parameter yet to be defined). Inclusion of the .meta information is at the discretion of the server (as it is for all FHIR interactions).

Binary Resources MAY be serialized as DocumentReference Resources with the content.attachment element populated as described in the [Attachments](#attachments) section below.

References in the resources returned MAY be relative URLs with the format <code>&lt;resource type&gt;/&lt;id&gt;</code>, or absolute URLs with the same structure rooted in the base URL for the server from which the export was performed. References will be resolved by looking for a resource with the specified type and id within the file set.

Example NDJSON output file:
```
{"id":"5c41cecf-cf81-434f-9da7-e24e5a99dbc2","name":[{"given":["Brenda"],"family":["Jackson"]}],"gender":"female","birthDate":"1956-10-14T00:00:00.000Z","resourceType":"Patient"}
{"id":"3fabcb98-0995-447d-a03f-314d202b32f4","name":[{"given":["Bram"],"family":["Sandeep"]}],"gender":"male","birthDate":"1994-11-01T00:00:00.000Z","resourceType":"Patient"}
{"id":"945e5c7f-504b-43bd-9562-a2ef82c244b2","name":[{"given":["Sandy"],"family":["Hamlin"]}],"gender":"female","birthDate":"1988-01-24T00:00:00.000Z","resourceType":"Patient"}

```

##### Endpoint

`GET [url from status request output field]`

##### Headers

- ```Accept``` (optional, defaults to ```application/fhir+ndjson```)

Specifies the format of the file being requested.

##### Response - Success

- HTTP status of ```200 OK```
- ```Content-Type``` header that matches the file format being delivered.  For files in ndjson format, SHALL be ```application/fhir+ndjson```
- Body of FHIR resources in newline delimited json - [ndjson](http://ndjson.org/) or other requested format

##### Response - Error

- HTTP Status Code of ```4XX``` or ```5XX```

##### Attachments

If resources in an output file contain elements of the type ```Attachment```, servers SHALL populate the ```Attachment.contentType``` code as well as either the ```data``` element or the ```url``` element. The ```url``` element SHALL be an absolute url that can be de-referenced to the attachment's content.

When the ```url``` element is populated with an absolute URL and the ```requiresAccessToken``` field in the Complete Status body is set to ```true```, the url location must be accessible by a client with a valid access token, and SHALL NOT require the use of additional authentication credentials.  When the ```url``` element is populated and the ```requiresAccessToken``` field in the Complete Status body is set to ```false```, the url location must be accessible by a client without an access token. 

Note that if a server copies files to the bulk data output endpoint or proxies requests to facilitate access from this endpoint, it may need to modify the ```Attachment.url``` element when generating the FHIR bulk data output files.

### Server Capability Documentation

This implementation guide is structured to support a wide variety of bulk data export use cases and server architectures. To provide clarity to developers on which capabilities are implemented in a particular server, server providers should ensure their documentation addresses the topics below. Future versions of this IG may define a computable format for this information as well.

- Does the server restrict responses to a specific "profile" like US Core, USCDI, or Blue Button?
- What approach does the server take to divide datasets into multiple files (eg. single file per the resource type, limit file size to 100MB, limit number of resources per file to 100,000)?
- Does the server support system-wide or Group-level export?
- What file formats does this server return?