<style type="text/css" rel="stylesheet">
	h3:before {content: none}
	h4:before {content: none}
</style>

### Current Draft - v1.1.0

#### Export Kickoff Request
* Permitted server support for kickoff requests via HTTP `POST` of a Parameters Resource
* Documented required and optional status of kickoff parameters for server implementors
* Expanded definition of `_since` parameter in Group level kickoff requests to permit servers to return resources that have an earlier `lastUpdated` date for patients that were added to the group after the supplied date
* Clarified which resources should be returned in scenarios where `_type` is populated 
* Added optional `_elements` kickoff parameter to filter resource data elements in the response
* Added optional `patient` kickoff parameter to filter resources in the response by patient id
* Added optional `includeAssociatedData` kickoff parameter and ValueSet for clients to indicate a set of pre-defined resources to omit or include with the response
* Provided guidance on server handling of unsupported kickoff parameters when a `prefer: handling=lenient header` is or is not provided
* Added recommended approach for clients to obtain historical data on new group members when not automatically included by server in Group level requests

#### Export Status Response
* Provided guidance for servers to return a transient error code in an `OperationOutcome` response when the error indicates a failure to obtain a status rather than a failure of the underlying job
* Permitted an error response that does not contain an `OperationOutcome` in the body when servers are unable to provide this

#### Export Complete Status Response
* Permitted clients to send a HTTP `DELETE` request the the status endpoint following a complete status to signal to the server that it no longer needs to retain the output files
* Clarified that the `error` field of the complete status response may include files containing `OperationOutcome` resources that are informational in nature
* Added `deleted` field in complete status response where servers can list resources that should be removed from downstream systems

#### Export - Data
* Clarified that resource references in the response may be relative or absolute
* Provided guidance for servers and clients to send and retrieve `Binary` resources and `Attachment` elements

#### Export - Other
* Added recommendations on server capability documentation

#### Backend Services Authorization
* Clarified that servers must support clients that provide a URL pointing to a JWKS Set on registration, as well as those that provide a JWKS Set directly on registration


### STU1 Technical Correction - v1.0.1

* Updated the CapabilityStatement to move the Patient and Group level export operations from the `rest.operation` element to `rest.resource.operation` elements and correct the OperationDefinition URLs
* Corrected conformance URL
* Added note on export complete status extension field description to clarify that extensions may be placed under to any field in the export complete status response and not just at the root level of the response


### STU1 - v1.0.0

* Initial release


