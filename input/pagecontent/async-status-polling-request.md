#### Bulk Data Status Request

After an asynchronous bulk request has been started, the {{ bulk_client_role }} MAY poll the status URL provided in the `Content-Location` header.

When polling for status, {{ bulk_client_role }}s SHOULD follow an [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff) approach. A {{ bulk_server_role }} SHOULD supply a [`Retry-After`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After) header with a delay time in seconds (for example, `120` to represent two minutes) or an HTTP-date (for example, `Fri, 31 Dec 1999 23:59:59 GMT`). When provided, {{ bulk_client_role }}s SHOULD use this information to inform the timing of future polling requests. The {{ bulk_server_role }} SHOULD keep an accounting of status queries received from a given {{ bulk_client_role }}, and if a {{ bulk_client_role }} is polling too frequently, the {{ bulk_server_role }} SHOULD respond with a `429 Too Many Requests` status code in addition to a `Retry-After` header, and optionally a FHIR `OperationOutcome` resource with further explanation. If excessively frequent status queries persist, the {{ bulk_server_role }} MAY return a `429 Too Many Requests` status code and terminate the session. Other standard HTTP `4XX` and `5XX` status codes MAY be used to identify errors as mentioned below.

When requesting status, the {{ bulk_client_role }} SHOULD use an `Accept` header indicating a content type of `application/json`. In the case that errors prevent the asynchronous operation from completing, the {{ bulk_server_role }} SHOULD respond with a FHIR `OperationOutcome` resource in JSON format.

<a name="separate-export-status"></a>
When a Prefer header value of `separate-export-status` was provided in the kick-off request and is supported by the {{ bulk_server_role }}, the HTTP status code in the response to this request SHALL reflect the status request itself, and not the asynchronous job. In this case, when the HTTP status code of this request is `200 OK`, the response SHALL also include an `X-Export-Status` header with an HTTP status code that reflects the status of the asynchronous job.

##### Endpoint

`GET [polling content location]`

##### Response - In-Progress Status

The {{ bulk_server_role }} SHALL indicate an in-progress asynchronous job with the following response status and headers:

| Kick-off request | HTTP status | `X-Export-Status` |
| --- | --- | --- |
| No [`separate-export-status`](#separate-export-status) | `202 Accepted` | Not present |
| [`separate-export-status`](#separate-export-status) | `200 OK` | `202 Accepted` |
{:.grid}

The {{ bulk_server_role }} MAY also return an `X-Progress` header with a text description of the status of the request that is less than 100 characters. The format of this description is at the {{ bulk_server_role }}'s discretion and MAY be a percentage complete value, or MAY be a more general status such as "in progress". The {{ bulk_client_role }} MAY parse the description, display it to the user, or log it.

##### Response - Error Status

The {{ bulk_server_role }} SHALL indicate an asynchronous job failure with the following response status and headers:

| Kick-off request | HTTP status | `X-Export-Status` |
| --- | --- | --- |
| No [`separate-export-status`](#separate-export-status) | `4XX` or `5XX` | Not present |
| [`separate-export-status`](#separate-export-status) | `200 OK` | `4XX` or `5XX` |
{:.grid}

The body of the response SHOULD be a FHIR `OperationOutcome` resource in JSON format. If this is not possible, such as when the infrastructure layer returning the error is not FHIR aware, the {{ bulk_server_role }} MAY return an error message in another format and include a corresponding value for the `Content-Type` header.

When the body is a FHIR `OperationOutcome` resource, the response SHALL include a `Content-Type` header of `application/fhir+json`.

In the case of a polling failure that does not indicate failure of the asynchronous job, a {{ bulk_server_role }} SHOULD use a [transient code](https://www.hl7.org/fhir/codesystem-issue-type.html#issue-type-transient) from the [IssueType valueset](https://www.hl7.org/fhir/codesystem-issue-type.html) when populating the FHIR `OperationOutcome` resource's `issue.code` element to indicate to the {{ bulk_client_role }} that it should retry the request at a later time.

*Note*: Even if some of the requested or generated resources cannot successfully be returned, the overall asynchronous operation MAY still succeed. In this case, the response `error` array of the completion manifest SHALL be populated with one or more files containing FHIR `OperationOutcome` resources to indicate what went wrong. In the case of a partial success, the {{ bulk_server_role }} SHALL use a `200` status code instead of `4XX` or `5XX`. The choice of when to determine that a job has failed in its entirety, as opposed to returning a partial success, is left to the {{ bulk_server_role }}.

##### Response - Complete Status

The {{ bulk_server_role }} SHALL indicate a completed asynchronous job with the following response status and headers:

| Kick-off request | HTTP status | `X-Export-Status` |
| --- | --- | --- |
| No [`separate-export-status`](#separate-export-status) | `200 OK` | Not present |
| [`separate-export-status`](#separate-export-status) | `200 OK` | `200 OK` |
{:.grid}

The response SHALL include a `Content-Type` header of `application/json` and a body containing the operation-specific manifest described below.

The {{ bulk_server_role }} SHOULD return an `Expires` header indicating when the files listed will no longer be available for access.
