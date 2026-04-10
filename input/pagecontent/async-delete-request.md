#### Bulk Data Delete Request

After an asynchronous bulk request has been started, a client MAY send a DELETE request to the URL provided in the `Content-Location` header to cancel the request. If the request has been completed, a server MAY use the request as a signal that the client is done retrieving files and that it is safe for the server to remove those from storage. Following the delete request, when subsequent requests are made to the polling location, the server SHALL return a `404 Not Found` error and an associated FHIR `OperationOutcome` resource in JSON format.

##### Endpoint

`DELETE [polling content location]`

##### Response - Success

- HTTP Status Code of `202 Accepted`
- Optionally a FHIR `OperationOutcome` resource in the body in JSON format

##### Response - Error

- HTTP status code of `4XX` or `5XX`
- The body SHALL be a FHIR `OperationOutcome` resource in JSON format
