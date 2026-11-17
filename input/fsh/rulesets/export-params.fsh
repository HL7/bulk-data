RuleSet: ExportParam_outputFormat
* parameter[+]
  * name = #_outputFormat
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is required for a Data Provider, optional for a Data Consumer.

    The format of the bulk data files generated through the [FHIR Asynchronous Bulk Interaction Pattern](async.html). Defaults to `application/fhir+ndjson`. The Data Provider SHALL support [Newline Delimited JSON](https://github.com/ndjson/ndjson-spec), but MAY choose to support additional output formats. The Data Provider SHALL accept the full content type of `application/fhir+ndjson` as well as the abbreviated representations `application/ndjson` and `ndjson`.
    """
  * type = #string

RuleSet: ExportParam_since
* parameter[+]
  * name = #_since
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is required for a Data Provider, optional for a Data Consumer.

    Resources will be included in the response if their state has changed after the supplied time (e.g., if `Resource.meta.lastUpdated` is later than the supplied `_since` time). The Data Provider MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the Data Provider does not maintain a last updated time, the Data Provider MAY include these resources in a response irrespective of the `_since` value supplied by a Data Consumer.
    """
  * type = #instant

RuleSet: ExportParam_until
* parameter[+]
  * name = #_until
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a Data Provider, optional for a Data Consumer.

    Resources will be included in the response if their state has changed before the supplied time (e.g., if `Resource.meta.lastUpdated` is earlier than the supplied `_until` time). The Data Provider MAY return resources that are referenced by the resources being returned regardless of when the referenced resources were last updated. For resources where the Data Provider does not maintain a last updated time, the Data Provider MAY include these resources in a response irrespective of the `_until` value supplied by a Data Consumer.
    """
  * type = #instant

RuleSet: ExportParam_type
* parameter[+]
  * name = #_type
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Support is optional for a Data Provider, optional for a Data Consumer.

    The response SHALL be filtered to only include resources of the specified resource type(s), except for related resources included by the Data Provider to provide context about the resources being exported (see [processing model](export.html#processing-model)) and additional resources included as a result of the `includeAssociatedData` parameter.

    Relative values are prefixed by `http://hl7.org/fhir/StructureDefinition/` such that a relative value of `Patient` resolves to the full URL of the Patient resource.

    To specify multiple types, multiple repetitions of this parameter are used - callers cannot use a single parameter with comma-delimited values. Note that versions 3.0.0 and earlier of this IG supplied `_type` as a comma-delimited query parameter.

    If this parameter is omitted, the Data Provider SHALL return all supported resources within the scope of the Data Consumer's authorization, though implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the [US Core Implementation Guide](http://www.hl7.org/fhir/us/core/). For Patient- and Group-level requests, the [Patient Compartment](https://www.hl7.org/fhir/compartmentdefinition-patient.html) SHOULD be used as a point of reference for recommended resources to be returned. Implementers should be aware that the Patient Compartment may not include all resources associated with a patient; for example, resources associated with a patient indirectly through membership in a Group may fall outside of the Patient Compartment. However, other resources outside of the Patient Compartment that are referenced by the resources being returned and would be helpful in interpreting the patient data MAY also be returned (such as Organization and Practitioner). When this behavior is supported, a Data Provider SHOULD document this support (for example, as narrative text, or by including a [GraphDefinition Resource](https://www.hl7.org/fhir/graphdefinition.html)).

    A Data Provider that is unable to support `_type` SHOULD return an error and FHIR `OperationOutcome` resource so the Data Consumer can re-submit a request omitting the `_type` parameter. If the Data Consumer explicitly asks for export of resources that the Data Provider does not support, or asks for only resource types that are outside the Patient Compartment, the Data Provider SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request. When a `Prefer: handling=lenient` header is included in the request, the Data Provider MAY process the request instead of returning an error.

    For example, a `_type` parameter with a value of `Observation` could be used to filter a given export response to return only FHIR `Observation` resources.
    """
  * type = #uri
  * binding
    * strength = #extensible
    * valueSet = "http://hl7.org/fhir/ValueSet/resource-types"

RuleSet: ExportParam_elements
* parameter[+]
  * name = #_elements
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Support is optional for a Data Provider, optional for a Data Consumer.

    When provided, the Data Provider SHOULD omit unlisted, non-mandatory elements from the resources returned. Elements SHOULD be of the form `[resource type].[element name]` (e.g., `Patient.id`) or `[element name]` (e.g., `id`) and only root elements in a resource are permitted. If the resource type is omitted, the element SHOULD be returned for all resources in the response where it is applicable.

    A Data Provider is not obliged to return just the requested elements. A Data Provider SHOULD always return mandatory elements whether they are requested or not. For guidance on indicating that resources are being returned with omitted elements, see the FHIR specification's definition of [`_elements`](https://hl7.org/fhir/R4/search.html#elements).

    A Data Provider that is unable to support `_elements` SHOULD return an error and a FHIR `OperationOutcome` resource so the Data Consumer can re-submit a request omitting the `_elements` parameter. When a `Prefer: handling=lenient` header is included in the request, the Data Provider MAY process the request instead of returning an error.
    """
  * type = #string

RuleSet: ExportParam_patient
* parameter[+]
  * name = #patient
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Support is optional for a Data Provider, optional for a Data Consumer.

    Not applicable to system level export requests. When provided, the Data Provider SHALL NOT return resources in the patient compartments belonging to patients outside of this list. This restriction does not apply to additional resources included as a result of the `includeAssociatedData` parameter. If a Data Consumer requests patients who are not present on the Data Provider (or in the case of a group level export, who are not members of the group), the Data Provider SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request.

    A Data Provider that is unable to support the `patient` parameter SHOULD return an error and FHIR `OperationOutcome` resource so the Data Consumer can re-submit a request omitting the `patient` parameter. When a `Prefer: handling=lenient` header is included in the request, the Data Provider MAY process the request instead of returning an error.
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
    Support is optional for a Data Provider, optional for a Data Consumer.

    When provided, requests the inclusion of additional resources associated with the resources otherwise selected for export. When omitted, no additional resources are included as a result of this parameter. See the [`includeAssociatedData` Parameter](export.html#includeassociateddata-parameter) section for details.

    A Data Provider that is unable to support the requested `includeAssociatedData` values SHOULD return an error and a FHIR `OperationOutcome` resource so the Data Consumer can re-submit a request that omits those values (for example, if provenance data is requested and a Data Provider does not retain provenance data). When a `Prefer: handling=lenient` header is included in the request, the Data Provider MAY process the request instead of returning an error.
  """
  * type = #Coding
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
    Support is optional for a Data Provider, optional for a Data Consumer.

    String of a FHIR REST search query.

    When provided, a Data Provider with support for the parameter and requested search queries SHALL filter the data in the response for resource types referenced in the `_typeFilter` expression to only include resources that meet the specified criteria, except for related resources included by the Data Provider to provide context about the resources being exported (see [processing model](export.html#processing-model)) and additional resources included as a result of the `includeAssociatedData` parameter. FHIR search result parameters such as `_include` and `_sort` SHALL NOT be used, and a query in the `_typeFilter` parameter SHALL have the search context of a single FHIR Resource Type.

    A Data Provider unable to support the requested `_typeFilter` queries SHOULD return an error and FHIR `OperationOutcome` resource so the Data Consumer can re-submit a request that omits those queries. When a `Prefer: handling=lenient` header is included in the request, the Data Provider MAY process the request instead of returning an error.
  """

RuleSet: ExportParam_organizeOutputBy
* parameter[+]
  * name = #organizeOutputBy
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a Data Provider, optional for a Data Consumer.

    URI of a FHIR resource type (see `_type` for relative values). The `outputOrganizedBy` element in the resulting manifest contains the resource type name (e.g., `Patient`), even when this parameter is an absolute URI.

    When provided, a Data Provider with support for the parameter SHALL organize the resources in output files by instances of the specified resource type, including a header for each resource of the type specified in the parameter, followed by the resource and resources in the output that contain references to that resource. When omitted, Data Providers SHALL organize each output file with resources of only a single type. See [details](export.html#bulk-data-output-file-organization), [example manifest](export.html#organize-output-by-manifest-example), and [example output file](export.html#organize-output-by-file-example).

    A Data Provider unable to structure output by the requested `organizeOutputBy` resource SHOULD return an error and FHIR `OperationOutcome` resource. When a `Prefer: handling=lenient` header is included in the request, the Data Provider MAY process the request instead of returning an error.
  """
  * type = #uri
  * binding
    * strength = #extensible
    * valueSet = "http://hl7.org/fhir/ValueSet/resource-types"

RuleSet: ExportParam_allowPartialManifests
* parameter[+]
  * name = #allowPartialManifests
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a Data Provider, optional for a Data Consumer.

    When provided, a Data Provider with support for the parameter MAY distribute the bulk data output files among multiple manifests, providing links for Data Consumers to page through the manifests ([see details](export.html#manifest-link)). Prior to all of the files in the export being available, the Data Provider MAY return a manifest with files that are available in an in-progress status response, and subsequently update the manifest with a paging link to a new manifest when additional files are ready for download ([see details](export.html#response---in-progress-status)).
  """
  * type = #boolean
