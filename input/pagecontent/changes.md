<style type="text/css" rel="stylesheet">
	h3:before {content: none}
	h4:before {content: none}
	h5:before {content: none}
</style>

### STU 4 - v4.0.0

#### Summary of changes since STU 3

* Added Bulk Submit and Bulk Submit Status operations.
* Added Bulk Publish operation.
* Renamed the `bulk-data` CapabilityStatement to `bulk-export` (`http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-export`), and added separate `bulk-submit` and `bulk-publish` CapabilityStatements. Servers that declared conformance with STU 3 by including `http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data` in `CapabilityStatement.instantiates` should use the new Bulk Export canonical URL.
* Migrated the FHIR Asynchronous Bulk Interaction Pattern documentation from the core FHIR spec into this IG and aligned with the current version of Bulk Export.
* Defined a logical model for the Bulk Data Manifest JSON format.
  - In STU 3, the `extension` property on any manifest object had a value of a JSON object where the properties are the extension name and the values are the extension value. In STU 4, the `extension` property contains an array of FHIR Extension elements.
  - Added optional `manifestType` and `outputFormat` elements.
  - Removed the deprecated `request` element.
  - Renamed the `error` element to `outcome`.
  - Changed the `outputOrganizedBy` element type to `uri`.
* Aligned Bulk Export kick-off requests with the FHIR Operations Framework.
  - Removed support for HTTP `GET` kick-off requests, requiring use of HTTP `POST` with a FHIR Parameters Resource.
  - Removed support for representing repeated Bulk Export parameters as multiple comma-delimited values in a single parameter value.
* Updated Bulk Export kick-off parameters.
  - Removed the `experimental` label from the `_elements` and `includeAssociatedData` parameters.
  - Changed the `includeAssociatedData` parameter type to a `Coding` from a `code`.
  - Changed the default `includeAssociatedData` behavior: when the parameter is omitted, no additional resources are included as a result of this parameter, so Provenance resources are no longer included by default unless they are part of the Data Provider's default export dataset or are requested using `_type`. Previously, when no provenance-related value was specified, Data Providers were required to include all available Provenance resources targeting resources in the Patient compartment for patient-level requests, and all available Provenance resources for system-level requests, unless `_type` excluded Provenance.
  - Changed the `_type` and `organizeOutputBy` parameter types to `uri`, with an extensible binding to the FHIR resource types value set.

#### Tickets applied after the STU 4 ballot

##### Non-compatible

* [FHIR-57952](https://jira.hl7.org/browse/FHIR-57952): Changed the `_type` and `organizeOutputBy` parameter types to `uri` with an extensible binding to the FHIR resource types value set.
* [FHIR-58963](https://jira.hl7.org/browse/FHIR-58963): Removed the `fileEncryptionKey` parameter from Bulk Submit, and noted that files may be encrypted and that a standard extension for encryption key information is expected in a future release of the FHIR Extensions Pack.
* [FHIR-59150](https://jira.hl7.org/browse/FHIR-59150): Required HTTP POST for kick-off requests, and required a Data Provider that does not accept HTTP GET kick-off requests to respond with `405 Method Not Allowed` and an `Allow` header.
* [FHIR-59152](https://jira.hl7.org/browse/FHIR-59152): Required a version-specific canonical in `manifestType` when it is populated, in all three manifests and their examples.

##### Compatible, substantive

* [FHIR-58835](https://jira.hl7.org/browse/FHIR-58835): Added Deleted Resources sections to Bulk Export, Bulk Submit, and Bulk Publish, with NDJSON examples of deletion transaction Bundles.
* [FHIR-58878](https://jira.hl7.org/browse/FHIR-58878): Noted that servers may reject requests, fail exports, or ignore Bulk Cohort Group member references outside their capabilities, and that servers SHOULD document their Group support.
* [FHIR-58921](https://jira.hl7.org/browse/FHIR-58921): Changed deleting already-processed data from a `stopped` Bulk Submit submission from SHALL to SHOULD.
* [FHIR-58962](https://jira.hl7.org/browse/FHIR-58962): Defined `includeAssociatedData` so that no associated resources are added when it is omitted, and clarified the Provenance resources each value includes.
* [FHIR-58964](https://jira.hl7.org/browse/FHIR-58964): Modeled the Bulk Publish manifest as a `return` output parameter of type Binary in the Bulk Publish OperationDefinition, returned as `application/json`, and recommended that Data Consumers send `Accept: application/json`.
* [FHIR-58965](https://jira.hl7.org/browse/FHIR-58965): Required TLS 1.2 or later for Bulk Publish (previously SHOULD).
* [FHIR-58980](https://jira.hl7.org/browse/FHIR-58980): Allowed a `fhirVersion` MIME-type parameter in the Bulk Submit `outputFormat`, and recommended that a Data Consumer reject a FHIR version it does not support.
* [FHIR-59015](https://jira.hl7.org/browse/FHIR-59015): Required the Bulk Submit Status `submitter` and `submissionId` to match values from earlier `$bulk-submit` requests.
* [FHIR-59016](https://jira.hl7.org/browse/FHIR-59016): Required servers to declare conformance by instantiating the new per-operation CapabilityStatements (SHOULD for Bulk Publish, which may not have a FHIR server).
* [FHIR-59139](https://jira.hl7.org/browse/FHIR-59139): Clarified that a partially successful export SHALL reference OperationOutcome files from the manifest `outcome` array, how those OperationOutcomes identify affected resources, and that OperationOutcomes describing omitted data SHALL use an `issue.severity` of `error` or `warning`.
* [FHIR-59140](https://jira.hl7.org/browse/FHIR-59140): Required Bulk Export Data Providers to use OperationOutcome resources to communicate parameters ignored under `Prefer: handling=lenient`.
* [FHIR-59142](https://jira.hl7.org/browse/FHIR-59142): Replaced the `_elements` guidance on the `SUBSETTED` tag with a reference to the FHIR specification.

##### Non-substantive

* [FHIR-58811](https://jira.hl7.org/browse/FHIR-58811): Clarified that status request text on the Bulk Submit page refers to Bulk Submit Status requests.
* [FHIR-58834](https://jira.hl7.org/browse/FHIR-58834): Added CapabilityStatements for Bulk Submit and Bulk Publish.
* [FHIR-58849](https://jira.hl7.org/browse/FHIR-58849): Removed bold formatting from the operations comparison table.
* [FHIR-58850](https://jira.hl7.org/browse/FHIR-58850): Grouped the operation and other specification pages under a Specification menu, and the support pages, including Downloads and Abbreviations, under a Support menu.
* [FHIR-58851](https://jira.hl7.org/browse/FHIR-58851): Noted that the Patient Compartment may not include all resources associated with a patient, such as resources linked to the patient only through Group membership.
* [FHIR-58896](https://jira.hl7.org/browse/FHIR-58896): Described how to export documents using DocumentReference resources and `_typeFilter`.
* [FHIR-58910](https://jira.hl7.org/browse/FHIR-58910): Clarified the difference between the two Bulk Publish example pages that use a `#pending` link.
* [FHIR-58919](https://jira.hl7.org/browse/FHIR-58919): Clarified that the Bulk Submit `fileRequestHeader` applies to requests for OAuth metadata, manifests, and files.
* [FHIR-58922](https://jira.hl7.org/browse/FHIR-58922): Linked Bulk Submit to the Bulk Data Manifest logical model instead of the Export page.
* [FHIR-58979](https://jira.hl7.org/browse/FHIR-58979): Removed the sentence asking Data Consumers to be robust to Data Providers that ignore `_typeFilter`.
* [FHIR-58983](https://jira.hl7.org/browse/FHIR-58983): Clarified how a Bulk Publish manifest without `manifestType` is interpreted.
* [FHIR-59000](https://jira.hl7.org/browse/FHIR-59000): Clarified the feedback channel row of the operations comparison table.
* [FHIR-59010](https://jira.hl7.org/browse/FHIR-59010): Added a public health reporting use case.
* [FHIR-59012](https://jira.hl7.org/browse/FHIR-59012): Clarified that Bulk Export request controls select data and do not require the Data Provider to transform it.
* [FHIR-59033](https://jira.hl7.org/browse/FHIR-59033): Aligned the Bulk Submit roles with the sequence diagram.
* [FHIR-59034](https://jira.hl7.org/browse/FHIR-59034): Fixed the link to the `operationoutcome-resource` extension.
* [FHIR-59067](https://jira.hl7.org/browse/FHIR-59067): Clarified that the Bulk Submit `fhirBaseUrl` does not need to identify an operational FHIR endpoint.
* [FHIR-59141](https://jira.hl7.org/browse/FHIR-59141): Described an optional pattern where the Data Consumer provides upload locations for Bulk Submit files.
* [FHIR-59151](https://jira.hl7.org/browse/FHIR-59151): Described how a Data Provider can advertise more than one version of Bulk Export in its CapabilityStatement.
* [FHIR-59153](https://jira.hl7.org/browse/FHIR-59153): Added notes on extensions and links to the logical models under the manifest field tables.
* [FHIR-59154](https://jira.hl7.org/browse/FHIR-59154): Required tokens on Bulk Export status and output file requests to have been granted the same scopes as the kick-off token, replacing the requirement that they cover all exported resources, and required a Data Provider to reject a token with different scopes with `403 Forbidden`.
* [FHIR-59155](https://jira.hl7.org/browse/FHIR-59155): Clarified which files a Bulk Submit Status delete request refers to.
* [FHIR-59156](https://jira.hl7.org/browse/FHIR-59156): Added an overview of how Bulk Submit reverses the Bulk Export roles.
* [FHIR-59158](https://jira.hl7.org/browse/FHIR-59158): Added SMART App Launch 2.0.0 or later to the Underlying Standards and the Authorization page.
* [FHIR-59160](https://jira.hl7.org/browse/FHIR-59160): Clarified that granted SMART scope constraints limit the exported data, and that export parameters do not expand authorization.
* [FHIR-59161](https://jira.hl7.org/browse/FHIR-59161): Clarified that `requiresAccessToken` applies to output file requests, not status requests.
* [FHIR-59172](https://jira.hl7.org/browse/FHIR-59172): Linked the Bulk Cohort API to the FHIR R5 Asynchronous Interaction Request pattern, with a note on use from FHIR R4.
* [FHIR-59202](https://jira.hl7.org/browse/FHIR-59202): Encouraged Data Consumers to use the kick-off parameters to limit requests to the data they need.
* [FHIR-59207](https://jira.hl7.org/browse/FHIR-59207): Noted that completing a submission does not mean every resource was accepted, and that use case IGs can describe how to reconcile partial acceptance.
* [FHIR-59211](https://jira.hl7.org/browse/FHIR-59211): Noted that breach reporting requirements are out of scope.
* [FHIR-59212](https://jira.hl7.org/browse/FHIR-59212): Changed the SHOULD on respecting individuals' data sharing preferences to non-normative encouragement, and added a pointer to the FHIR security guidance.
* [FHIR-59370](https://jira.hl7.org/browse/FHIR-59370): Added an informative Processing Submissions section on resource identity and storage in Bulk Submit.

#### Tickets applied before the STU 4 ballot

##### Non-compatible

* [FHIR-53437](https://jira.hl7.org/browse/FHIR-53437): Changed the `includeAssociatedData` parameter type from `code` to `Coding`, and removed the reference to comma-delimited values.
* [FHIR-56170](https://jira.hl7.org/browse/FHIR-56170): Defined a logical model for the Bulk Data manifest, with manifest extensions represented as FHIR `Extension` elements instead of a JSON object.
* [FHIR-57479](https://jira.hl7.org/browse/FHIR-57479): Removed HTTP GET kick-off requests and comma-delimited parameter values, so Bulk Export uses HTTP POST with a Parameters resource.
* [FHIR-57480](https://jira.hl7.org/browse/FHIR-57480): Removed the `request` element from the Bulk Export manifest, renamed `error` to `outcome`, added an optional `outputFormat` element, and made `outcome` optional.
* [FHIR-57481](https://jira.hl7.org/browse/FHIR-57481): Made the same manifest changes in the FHIR Asynchronous Bulk Interaction Pattern.

##### Compatible, substantive

* [FHIR-56171](https://jira.hl7.org/browse/FHIR-56171): Added the `$bulk-submit` and `$bulk-submit-status` operations.
* [FHIR-56172](https://jira.hl7.org/browse/FHIR-56172): Added the `$bulk-publish` operation.

##### Non-substantive

* [FHIR-53483](https://jira.hl7.org/browse/FHIR-53483): Removed the `experimental` label from the Bulk Export `_elements` and `includeAssociatedData` parameters.
* [FHIR-56860](https://jira.hl7.org/browse/FHIR-56860): Moved the FHIR Asynchronous Bulk Interaction Pattern into this IG and aligned its text with Bulk Export.

### STU 3 - v3.0.0
* Added support for partial export manifests to enable servers to make some files available prior to all of the files being ready and to split large lists of files across multiple manifests. Clients can select this behavior using the new `allowPartialManifests` kick-off request parameter.
* Added support for organizing the resources in output files by instances of the specified resource type, with a header for each instance of the resource type followed by the resource and resources in the output that reference it. Clients can select this behavior using the new `organizeOutputBy` kick-off request parameter.
* Removed the "experimental" label from the `_typeFilter` kickoff parameter since it has been widely implemented, clarified its documentation and approach to boolean logic, and documented the interaction with other filters.
* Added optional `_until` kickoff parameter on the Bulk Data kickoff request as an analog to the `_since` parameter to enable users to specify a cutoff modification timestamp for the resources in the response.
* Added guidance on the use of FHIR Groups with Bulk Export, and added a Group profile to support the creation of characteristic-based cohorts using coarse-grained filters to more efficiently export data on sets of patients from a source system.
* Moved guidance on the use of capability URLs from a separate confluence page into the Bulk Data Output File Request section of the IG and added guidance on content encoding.
* Defined an extension for a server to indicate search parameters in the capability statement that are accessible with the REST API, but not available when using the Bulk Export operation.


### STU 2 - v2.0.0

#### Export Kickoff Request
* Permitted server support for kickoff requests via HTTP `POST` of a Parameters Resource
* Documented required and optional status of kickoff parameters for server implementors
* Documented guidance on use and interpretation of repeated parameters
* Expanded definition of `_since` parameter in Group level kickoff requests to permit servers to return resources that have an earlier `lastUpdated` date for patients that were added to the group after the supplied date
* Clarified which resources should be returned in scenarios where `_type` is populated
* Added optional `_elements` kickoff parameter to filter resource data elements in the response
* Added optional `patient` kickoff parameter to filter resources in the response by patient id
* Added optional `includeAssociatedData` kickoff parameter and ValueSet for clients to indicate a set of pre-defined resources to omit or include with the response
* Provided guidance on server handling of unsupported kickoff parameters when a `Prefer: handling=lenient` header is or is not provided
* Added recommended approach for clients to obtain historical data on new group members when not automatically included by server in Group level requests
* Clarified that resources associated with groups containing non-patient members (e.g., groups of practitioners or groups of devices) may be exported using a group-level bulk export request
* Updated the `Accept` and `Prefer` header requirements from required to recommended for clients, with servers having discretion on whether to return an error or presume a default if omitted
* Clarified server behavior in cases where the modification date of resources is not tracked and a `_since` parameter is provided by a client

#### Export Status Response
* Provided guidance for servers to return a transient error code in an `OperationOutcome` response when the error indicates a failure to obtain a status rather than a failure of the underlying job
* Permitted an error response that does not contain an `OperationOutcome` in the body when servers are unable to provide this

#### Export Complete Status Response
* Permitted clients to send an HTTP `DELETE` request to the status endpoint following a complete status to signal to the server that it no longer needs to retain the output files
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


### STU 1 Technical Correction - v1.0.1

* Updated the CapabilityStatement to move the Patient and Group level export operations from the `rest.operation` element to `rest.resource.operation` elements and correct the OperationDefinition URLs
* Corrected conformance URL
* Added a note on the export complete status extension field description to clarify that extensions may be placed under any field in the export complete status response and not just at the root level of the response


### STU 1 - v1.0.0

* Initial release
