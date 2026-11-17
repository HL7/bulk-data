Instance: bulk-submit
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-submit"
* name = "BulkSubmit"
* title = "FHIR Bulk Data Submit"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 2
* kind = #operation
* affectsState = true
* date = "2025-01-27"
* jurisdiction = $m49.htm#001 "World"
* description = """
    FHIR Operation through which an authenticated and authorized Data Provider submits Bulk FHIR Data to a Data Consumer and receives status information regarding the Data Consumer's receipt and processing of the data. The Data Provider provides one or more manifest URLs pointing to pre-coordinated FHIR data sets, along with metadata needed for the Data Consumer to retrieve and process the files.
    """
* code = #bulk-submit
* system = true
* type = false
* instance = false

* parameter[+]
  * name = #submitter
  * use = #in
  * min = 1
  * max = "1"
  * documentation = """
    The submitter SHALL match a system and value specified by the Data Consumer (coordinated out-of-band or in an implementation guide specific to a use case).
    """
  * type = #Identifier

* parameter[+]
  * name = #submissionId
  * use = #in
  * min = 1
  * max = "1"
  * documentation = """
    The value SHALL be unique for the `submitter`.
    """
  * type = #string

* parameter[+]
  * name = #submissionStatus
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    System of `http://hl7.org/fhir/event-status`, code of `in-progress` (default if parameter is omitted), `completed` or `stopped`. Once a request has been submitted with a `submissionStatus` of `stopped` or `completed`, additional requests SHALL NOT be submitted for that `submitter` and `submissionId` combination. At least one of the `submissionStatus` and `manifestUrl` parameters SHALL be populated.
    """
  * type = #Coding
  * binding.strength = #required
  * binding.valueSet = Canonical(SubmissionStatusValueSet)

* parameter[+]
  * name = #manifestUrl
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Url pointing to a [Bulk Data Manifest](StructureDefinition-BulkDataManifest.html) with a pre-coordinated FHIR data set. Files in multiple submitted manifests with the same `submitter` and `submissionId` SHALL be treated by the Data Consumer as if they were submitted in a single manifest. This parameter MAY be omitted when the operation is being called to set the `submissionStatus` to `completed` or `stopped`, or to remove a previously submitted manifest using `replacesManifestUrl`. The value SHALL be unique for all manifests that share a `submitter` and `submissionId` combination. At least one of the `submissionStatus` and `manifestUrl` parameters SHALL be populated. When this parameter is populated, the `fhirBaseUrl` parameter SHALL also be populated.
    """
  * type = #url

* parameter[+]
  * name = #replacesManifestUrl
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    The url of a previously submitted manifest that has the same `submissionId` and `submitter` as this request. When provided, the Data Consumer SHALL discard the data from the referenced manifest and, when `manifestUrl` is also populated, replace it with the data in that manifest. If the url is invalid or the Data Consumer is unable to replace the data, it SHALL return an error response as described in [Response - Error](submit.html#response---error).
    """
  * type = #url

* parameter[+]
  * name = #outputFormat
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    The format for the Bulk Data files in the manifest. The MIME-type MAY include a MIME-type parameter of `fhirVersion` as described in the [FHIR specification](https://hl7.org/fhir/http.html#version-parameter) to indicate which version of FHIR the resources in the Bulk Data files are based on. A Data Consumer that does not support the indicated `fhirVersion` SHOULD reject the request with an HTTP `4XX` status and an OperationOutcome. When `outputFormat` is omitted, it defaults to `application/fhir+ndjson` (Newline Delimited JSON). When the `fhirVersion` MIME-type parameter is omitted, the FHIR version SHALL be pre-coordinated between the Data Provider and Data Consumer. All of the resources in a submission SHALL use the same version of FHIR.
    """
  * type = #string

* parameter[+]
  * name = #fhirBaseUrl
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Base URL to be used by the Data Consumer when resolving relative references in the submitted resources. The URL does not need to identify an operational FHIR REST endpoint or be dereferenceable by the Data Consumer. When the `manifestUrl` parameter is populated, this parameter SHALL be populated.
    """
  * type = #url

* parameter[+]
  * name = #fileRequestHeader
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    HTTP headers that the Data Consumer SHALL use when requesting the OAuth metadata, the manifest(s), and the files they reference.
    """
  * part[+]
    * name = #headerName
    * use = #in
    * min = 1
    * max = "1"
    * type = #string
  * part[+]
    * name = #headerValue
    * use = #in
    * min = 1
    * max = "1"
    * type = #string

* parameter[+]
  * name = #oauthMetadataUrl
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Location that a Data Consumer can use to obtain the information needed to retrieve files protected using OAuth 2.0. The url SHALL be the path to a [FHIR Authorization Endpoint and Capabilities Discovery file](https://hl7.org/fhir/smart-app-launch/conformance.html#using-well-known) or another [OAuth 2.0 Protected Resource Metadata file](https://datatracker.ietf.org/doc/rfc9728/) that is registered in the [IANA Well-Known URIs Registry](https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml).
    """
  * type = #url

* parameter[+]
  * name = #metadata
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Pre-coordinated data relevant to the submission, passed from the Data Provider to the Data Consumer. Each `metadata` parameter contains a `parameterUrl` part with an absolute URL identifying the metadata item and a `parameterValue` part with its value. This parameter MAY be repeated. Specific `parameterUrl` values are defined in implementation guides for particular use cases.
    """
  * part[+]
    * name = #parameterUrl
    * use = #in
    * min = 1
    * max = "1"
    * documentation = """
      An absolute URL identifying this metadata parameter.
      """
    * type = #uri
  * part[+]
    * name = #parameterValue
    * use = #in
    * min = 1
    * max = "1"
    * documentation = """
      The value for this metadata parameter.
      """
    * type = #string

* parameter[+]
  * name = #import
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Pre-coordinated options relevant to how the data will be processed, passed from the Data Provider to the Data Consumer. For example, a Data Consumer might allow the Data Provider to specify whether or not existing data should be replaced with the data in the submission. Each `import` parameter contains a `parameterUrl` part with an absolute URL identifying the option and a `parameterValue` part with its value. This parameter MAY be repeated. Specific `parameterUrl` values are defined in implementation guides for particular use cases.
    """
  * part[+]
    * name = #parameterUrl
    * use = #in
    * min = 1
    * max = "1"
    * documentation = """
      An absolute URL identifying this import parameter.
      """
    * type = #uri
  * part[+]
    * name = #parameterValue
    * use = #in
    * min = 1
    * max = "1"
    * documentation = """
      The value for this import parameter.
      """
    * type = #string
