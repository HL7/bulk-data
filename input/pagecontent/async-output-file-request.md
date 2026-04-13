#### Bulk Data Output File Request

Using the URLs supplied by the server in the manifest, a client MAY download the referenced files within the time period specified in the `Expires` header, if present. A client MAY re-fetch the manifest if file links have expired, and a server MAY provide updated links or an updated `Expires` timestamp in response.

As long as a server is following relevant security guidance, it MAY generate manifests where the `requiresAccessToken` field is `true` or `false`, including for servers available on the public internet.

If the `requiresAccessToken` field in the manifest is set to `true`, the request SHALL include a valid access token.

If the `requiresAccessToken` field is set to `false` and no additional authorization-related extensions are present in the relevant manifest entry, then the URLs SHALL be dereferenceable directly as capability URLs. A client SHALL NOT provide a SMART Backend Services access token when dereferencing a URL from a manifest entry where `requiresAccessToken` is `false`.

Returned content SHALL include only the most recent version of any returned resources unless the client explicitly requests different behavior in a fashion supported by the server. Inclusion of the `Resource.meta` information in the resources is at the discretion of the server, as it is for all FHIR interactions.

A client SHOULD provide an `Accept-Encoding` header when requesting files and SHOULD include `gzip` compression as one of the encoding options in the header. A server SHALL provide files as uncompressed, with `gzip` compression, or with another compression format from the `Accept-Encoding` header. When compression is used, a server SHALL communicate this to the client by including a `Content-Encoding` header in the response. A client SHALL accept files that are uncompressed or encoded with `gzip` compression, and MAY accept files encoded with other compression formats.

##### Endpoint

`GET [url from manifest output, deleted, or error field]`

##### Headers

- `Accept` (optional, defaults to `application/fhir+ndjson`)

Specifies the format of the file being requested.

##### Response - Success

- HTTP status of `200 OK`
- `Content-Type` header that matches the file format being delivered. For files in NDJSON format, SHALL be `application/fhir+ndjson`
- Body of FHIR resources in newline delimited JSON, [NDJSON](https://github.com/ndjson/ndjson-spec), or another requested format

##### Response - Error

- HTTP Status Code of `4XX` or `5XX`
