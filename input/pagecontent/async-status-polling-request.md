#### Bulk Data Status Request

After an asynchronous bulk request has been started, the client MAY poll the status URL provided in the `Content-Location` header.

Clients SHOULD follow an [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff) approach when polling for status. A server SHOULD supply a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header with a delay time in seconds (for example, `120` to represent two minutes) or an HTTP-date (for example, `Fri, 31 Dec 1999 23:59:59 GMT`). When provided, clients SHOULD use this information to inform the timing of future polling requests. The server SHOULD keep an accounting of status queries received from a given client, and if a client is polling too frequently, the server SHOULD respond with a `429 Too Many Requests` status code in addition to a `Retry-After` header, and optionally a FHIR `OperationOutcome` resource with further explanation. If excessively frequent status queries persist, the server MAY return a `429 Too Many Requests` status code without returning a status answer. It MAY either return a `Retry-After` header indicating how long the client should wait before polling again, or it MAY abandon the asynchronous operation entirely and force a retry. Other standard HTTP `4XX` and `5XX` status codes may be used to identify errors as mentioned below.

When requesting status, the client SHOULD use an `Accept` header indicating a content type of `application/json`. In the case that errors prevent the asynchronous operation from completing, the server SHOULD respond with a FHIR `OperationOutcome` resource in JSON format.

##### Endpoint

`GET [polling content location]`

##### Response - In-Progress Status

- HTTP Status Code of `202 Accepted`
- Optionally, the server MAY return an `X-Progress` header with a text description of the status of the request that is less than 100 characters. The format of this description is at the server's discretion and MAY be a percentage complete value, or MAY be a more general status such as "in progress". The client MAY parse the description, display it to the user, or log it.

##### Response - Error Status

- HTTP status code of `4XX` or `5XX`
- `Content-Type` header of `application/fhir+json` when the body is a FHIR `OperationOutcome` resource
- The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible, such as when the infrastructure layer returning the error is not FHIR aware, the server MAY return an error message in another format and include a corresponding value for the `Content-Type` header.

In the case of a polling failure that does not indicate failure of the asynchronous job, a server SHOULD use a [transient code](https://www.hl7.org/fhir/codesystem-issue-type.html#issue-type-transient) from the [IssueType valueset](https://www.hl7.org/fhir/codesystem-issue-type.html) when populating the FHIR `OperationOutcome` resource's `issue.code` element to indicate to the client that it should retry the request at a later time.

*Note*: Even if some of the requested or generated resources cannot successfully be returned, the overall asynchronous operation MAY still succeed. In this case, the response `error` array of the completion manifest SHALL be populated with one or more files containing FHIR `OperationOutcome` resources to indicate what went wrong. In the case of a partial success, the server SHALL use a `200` status code instead of `4XX` or `5XX`. The choice of when to determine that a job has failed in its entirety, as opposed to returning a partial success, is left to the server implementer.

##### Response - Complete Status

- HTTP status of `200 OK`
- `Content-Type` header of `application/json`
- The server SHOULD return an `Expires` header indicating when the files listed will no longer be available for access
- A body containing the operation-specific manifest described below
