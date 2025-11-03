<style type="text/css" rel="stylesheet">
	h3:before {content: none}
	h4:before {content: none}
</style>

### Future

The Argonaut FHIR accelerator is leading a community effort to specify two new operations, [Bulk Submit ($bulk-submit)](https://hackmd.io/@argonaut/rJoqHZrPle) and [Bulk Publish ($bulk-publish)](https://hackmd.io/@argonaut/Sy7wjS81Wg), that will be incorporated into a future release of this specification (discuss at [chat.fhir.org](https://chat.fhir.org/#narrow/channel/179250-bulk-data)).


### STU3 - v3.0.0
* Added support for partial export manifests to enable servers to make some files available prior to all of the files being ready and to split large lists of files across multiple manifests. Clients can select this behavior using the new `allowPartialManifests` kick-off request parameter. 
* Added support for organizing the resources in output files by instances of the specified resource type, with a header for each instance of the resource type followed by the resource and resources in the output that reference it. Clients can select this behavior using the new `organizeOutputBy` kick-off request parameter.
* Removed the "experimental" label from the `_typeFilter` kickoff parameter since it has been widely implemented, clarified its documentation and approach to boolean logic, and documented the interaction with other filters.
* Added optional `_until` kickoff parameter on the Bulk Data kickoff request as an analog to the `_since` parameter to enable users to specify a cutoff modification timestamp for the resources in the response.
* Added guidance on the use of FHIR Groups with Bulk Export, and added a Group profile to support the creation of characteristic based cohorts using coarse-grained filters to more efficiently export data on sets of patients from a source system.
* Moved guidance on the use of capability urls from a separate confluence page into the Bulk Data Output File Request section of the IG and added guidance on content encoding.
* Defined an extension for a server to indicate search parameters in the capability statement that are accessible with the REST API, but not available when using the Bulk Export operation.


### STU2 - v2.0.0

#### Export Kickoff Request
* Permitted server support for kickoff requests via HTTP `POST` of a Parameters Resource
* Documented required and optional status of kickoff parameters for server implementors
* Documented guidance on use and interpretation of repeated parameters
* Expanded definition of `_since` parameter in Group level kickoff requests to permit servers to return resources that have an earlier `lastUpdated` date for patients that were added to the group after the supplied date
* Clarified which resources should be returned in scenarios where `_type` is populated 
* Added optional `_elements` kickoff parameter to filter resource data elements in the response
* Added optional `patient` kickoff parameter to filter resources in the response by patient id
* Added optional `includeAssociatedData` kickoff parameter and ValueSet for clients to indicate a set of pre-defined resources to omit or include with the response
* Provided guidance on server handling of unsupported kickoff parameters when a `prefer: handling=lenient header` is or is not provided
* Added recommended approach for clients to obtain historical data on new group members when not automatically included by server in Group level requests
* Clarified that resources associated with groups containing non-patient members (e.g., groups of practitioners or groups of devices) may be exported using a group-level bulk export request
* Updated the `Accept` and `Prefer` header requirements from required to recommended for clients, with servers having discretion on whether to return an error or presume a default if omitted
* Clarified server behavior in cases where the modification date of resources is not tracked and a `_since` parameter is provided by a client

#### Export Status Response
* Provided guidance for servers to return a transient error code in an `OperationOutcome` response when the error indicates a failure to obtain a status rather than a failure of the underlying job
* Permitted an error response that does not contain an `OperationOutcome` in the body when servers are unable to provide this

#### Export Complete Status Response
* Permitted clients to send a HTTP `DELETE` request the the status endpoint following a complete status to signal to the server that it no longer needs to retain the output files
* Clarified that the `output.url` field in the complete status response should be an absolute path
* Clarified that the `error` field of the complete status response may include files containing `OperationOutcome` resources that are informational in nature
* Added `deleted` field in complete status response where servers can list resources that should be removed from downstream systems

#### Export - Data
* Clarified that resource references in the response may be relative or absolute
* Provided guidance for servers and clients to send and retrieve `Binary` resources and `Attachment` elements
* Changed requirement to populate `Attachment.contentType` in Attachments from a requirement to a recommendation to align with the core FHIR spec

#### Export - Other
* Added recommendations on server capability documentation

#### Backend Services Authorization
* Migrated and integrated documentation into the SMART App Launch Implementation Guide
* Clarified that servers must support clients that provide a URL pointing to a JWKS Set on registration, as well as those that provide a JWKS Set directly on registration
* Clarified authorization requirements for status and data requests
* Clarified the algorithm for verifying a client's public key
* Clarified scopes language and described optional support for SMART v2 scope


### STU1 Technical Correction - v1.0.1

* Updated the CapabilityStatement to move the Patient and Group level export operations from the `rest.operation` element to `rest.resource.operation` elements and correct the OperationDefinition URLs
* Corrected conformance URL
* Added note on export complete status extension field description to clarify that extensions may be placed under to any field in the export complete status response and not just at the root level of the response


### STU1 - v1.0.0

* Initial release
