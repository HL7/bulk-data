RuleSet: ExportParam_outputFormat
* parameter[+]
  * name = #_outputFormat
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is required for a server, optional for a client.

    The format for the requested Bulk Data files to be generated as per [FHIR Asynchronous Request Pattern](http://hl7.org/fhir/R4/async.html). Defaults to `application/fhir+ndjson`. The server SHALL support [Newline Delimited JSON](https://github.com/ndjson/ndjson-spec), but MAY choose to support additional output formats. The server SHALL accept the full content type of `application/fhir+ndjson` as well as the abbreviated representations `application/ndjson` and `ndjson`.
    """
  * type = #string

RuleSet: ExportParam_since
* parameter[+]
  * name = #_since
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is required for a server, optional for a client.

    Resources will be included in the response if their state has changed after the supplied time (e.g., if `Resource.meta.lastUpdated` is later than the supplied `_since` time). The server MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the server does not maintain a last updated time, the server MAY include these resources in a response irrespective of the `_since` value supplied by a client.
    """
  * type = #instant

RuleSet: ExportParam_until
* parameter[+]
  * name = #_until
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a server, optional for a client.

    Resources will be included in the response if their state has changed before the supplied time (e.g., if `Resource.meta.lastUpdated` is earlier than the supplied `_until` time). The server MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the server does not maintain a last updated time, the server MAY include these resources in a response irrespective of the `_until` value supplied by a client.
    """
  * type = #instant

RuleSet: ExportParam_type
* parameter[+]
  * name = #_type
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Support is optional for a server, optional for a client.

    The response SHALL be filtered to only include resources of the specified resource types(s).

    If this parameter is omitted, the server SHALL return all supported resources within the scope of the client authorization, though implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/). For Patient- and Group-level requests, the [Patient Compartment](https://www.hl7.org/fhir/compartmentdefinition-patient.html) SHOULD be used as a point of reference for recommended resources to be returned. However, other resources outside of the Patient Compartment that are referenced by the resources being returned and would be helpful in interpreting the patient data MAY also be returned (such as Organization and Practitioner). When this behavior is supported, a server SHOULD document this support (for example, as narrative text, or by including a [GraphDefinition Resource](https://www.hl7.org/fhir/graphdefinition.html)).

    A server that is unable to support `_type` SHOULD return an error and FHIR `OperationOutcome` resource so the client can re-submit a request omitting the `_type` parameter. If the client explicitly asks for export of resources that the Bulk Data server doesn't support, or asks for only resource types that are outside the Patient Compartment, the server SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request. When a `Prefer: handling=lenient` header is included in the request, the server MAY process the request instead of returning an error.

    For example `_type=Observation` could be used to filter a given export response to return only FHIR `Observation` resources.
    """
  * type = #string

RuleSet: ExportParam_elements
* parameter[+]
  * name = #_elements
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Experimental support is optional for a server, optional for a client.

    When provided, the server SHOULD omit unlisted, non-mandatory elements from the resources returned. Elements SHOULD be of the form `[resource type].[element name]` (e.g., `Patient.id`) or `[element name]` (e.g., `id`) and only root elements in a resource are permitted. If the resource type is omitted, the element SHOULD be returned for all resources in the response where it is applicable.

    A server is not obliged to return just the requested elements. A server SHOULD always return mandatory elements whether they are requested or not. A server SHOULD mark the resources with the tag `SUBSETTED` to ensure that the incomplete resource is not actually used to overwrite a complete resource.

    A server that is unable to support `_elements` SHOULD return an error and a FHIR `OperationOutcome` resource so the client can re-submit a request omitting the `_elements` parameter. When a `Prefer: handling=lenient` header is included in the request, the server MAY process the request instead of returning an error.
    """
  * type = #string

RuleSet: ExportParam_patient
* parameter[+]
  * name = #patient
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Support is optional for a server, optional for a client.

    Not applicable to system level export requests. This parameter is only valid in kickoff requests initiated through a HTTP POST request. When provided, the server SHALL NOT return resources in the patient compartments belonging to patients outside of this list. If a client requests patients who are not present on the server (or in the case of a group level export, who are not members of the group), the server SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request.

    A server that is unable to support the `patient` parameter SHOULD return an error and FHIR `OperationOutcome` resource so the client can re-submit a request omitting the `patient` parameter. When a `Prefer: handling=lenient` header is included in the request, the server MAY process the request instead of returning an error.
    """
  * type = #Reference
  * targetProfile = "http://hl7.org/fhir/StructureDefinition/Patient"

RuleSet: ExportParam_includeAssociatedData
* parameter[+]
  * name = #includeAssociatedData
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Experimental support is optional for a server, optional for a client.

    When provided, a server with support for the parameter and requested values SHALL return or omit a pre-defined set of FHIR resources associated with the request.

    A server that is unable to support the requested `includeAssociatedData` values SHOULD return an error and a FHIR `OperationOutcome` resource so the client can re-submit a request that omits those values (for example, if a server does not retain provenance data). When a `Prefer: handling=lenient` header is included in the request, the server MAY process the request instead of returning an error.

    A client MAY include one or more of the following values. If multiple conflicting values are included, the server SHALL apply the least restrictive value (value that will return the largest dataset).

    * `LatestProvenanceResources`: Export will include the most recent Provenance resources associated with each of the non-provenance resources being returned. Other Provenance resources will not be returned.
    * `RelevantProvenanceResources`: Export will include all Provenance resources associated with each of the non-provenance resources being returned.
    * `_[custom value]`: A server MAY define and support custom values that are prefixed with an underscore (e.g., `_myCustomPreset`).
  """
  * type = #code
  * binding
    * strength = #extensible
    * valueSet = Canonical(IncludeAssociatedDataValueSet)

RuleSet: ExportParam_typeFilter
* parameter[+]
  * name = #_typeFilter
  * use = #in
  * min = 0
  * max = "*"
  * type = #string
  * documentation = """
    Support is optional for a server, optional for a client.

    String of a FHIR REST search query.

    When provided, a server with support for the parameter and requested search queries SHALL filter the data in the response for resource types referenced in the typeFilter expression to only include resources that meet the specified criteria. FHIR search result parameters such as `_include` and `_sort` SHALL NOT be used and a query in the `_typeFilter` parameter SHALL have the search context of a single FHIR Resource Type. [See details](export.html#_typefilter-query-parameter).

    A server unable to support the requested `_typeFilter` queries SHOULD return an error and FHIR `OperationOutcome` resource so the client can re-submit a request that omits those queries. When a `Prefer: handling=lenient` header is included in the request, the server MAY process the request instead of returning an error.
  """

RuleSet: ExportParam_organizeOutputBy
* parameter[+]
  * name = #organizeOutputBy
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a server, optional for a client.

    String of a FHIR resource type.

    When provided, a server with support for the parameter SHALL organize the resources in output files by instances of the specified resource type, including a header for each resource of the type specified in the parameter, followed by the resource and resources in the output that contain references to that resource. When omitted, servers SHALL organize each output file with resources of only single type. See [details](export.html#bulk-data-output-file-organization), [example manifest](export.html#organize-output-by-manifest-example), and [example output file](export.html#organize-output-by-file-example).

    A server unable to structure output by the requested `organizeOutputBy` resource SHOULD return an error and FHIR `OperationOutcome` resource. When a `Prefer: handling=lenient` header is included in the request, the server MAY process the request instead of returning an error.
  """
  * type = #string

RuleSet: ExportParam_allowPartialManifests
* parameter[+]
  * name = #allowPartialManifests
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a server, optional for a client.

    When provided, a server with support for the parameter MAY distribute the bulk data output files among multiple manifests, providing links for clients to page through the manifests ([see details](export.html#manifest-link)). Prior to all of the files in the export being available, the server MAY return a manifest with files that are available along with a `202 Accepted` HTTP response status, and subsequently update the manifest with a paging link to a new manifest when additional files are ready for download ([see details](export.html#response---in-progress-status)).
  """
  * type = #boolean
