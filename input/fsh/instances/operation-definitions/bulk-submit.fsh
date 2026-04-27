Instance: bulk-submit
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-submit"
* version = "1.0.0"
* name = "BulkSubmit"
* title = "FHIR Bulk Data Submit"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 2
* kind = #operation
* date = "2025-01-27"
* jurisdiction = $m49.htm#001 "World"
* description = """
    FHIR Operation through which an authenticated and authorized Data Provider may submit Bulk FHIR Data to a Data Consumer and receive status information regarding the Data Consumer's receipt and processing of the data. The Data Provider provides one or more manifest URLs pointing to pre-coordinated FHIR data sets, along with metadata needed for the Data Consumer to retrieve and process the files.
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
    The submitter must match a system and code specified by the Data Consumer (coordinated out-of-band or in an implementation guide specific to a use case).
    """
  * type = #Identifier

* parameter[+]
  * name = #submissionId
  * use = #in
  * min = 1
  * max = "1"
  * documentation = """
    The value must be unique for the `submitter`.
    """
  * type = #string

* parameter[+]
  * name = #submissionStatus
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    System of `http://hl7.org/fhir/uv/bulkdata/ValueSet/submission-status`, code of `in-progress` (default if parameter is omitted), `complete` or `aborted`. Once a request has been submitted with a `submissionStatus` of `aborted` or `complete`, no additional requests may be submitted for that `submitter` and `submissionId` combination. At least one of the `submissionStatus` and `manifestUrl` parameters SHALL be populated.
    """
  * type = #Coding

* parameter[+]
  * name = #manifestUrl
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Url pointing to a [Bulk Export Manifest](https://build.fhir.org/ig/HL7/bulk-data/export.html#response---output-manifest) with a pre-coordinated FHIR data set. Files in multiple submitted manifests with the same `submitter` and `submissionId` SHALL be treated by the Data Consumer as if they were submitted in a single manifest. This parameter MAY be omitted when the operation is being called to set the submissionStatus to `complete` or `aborted`. The value must be unique for all manifests that share a `submitter` and `submissionId` combination. At least one of the `submissionStatus` and `manifestUrl` parameters SHALL be populated. When this parameter is populated, the `fhirBaseUrl` parameter SHALL also be populated.
    """
  * type = #url

* parameter[+]
  * name = #replacesManifestUrl
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    The url of a previously submitted manifest that has the same `submissionId` and `submitter` as this request. When provided, Data Consumer SHALL replace the data in the referenced manifest with the one in the current request. If the url is invalid or the Data Consumer is unable to replace the data, it should respond to the request with an OperationOutcome describing the error.
    """
  * type = #url

* parameter[+]
  * name = #outputFormat
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    The format for the Bulk Data files in the manifest. The MIME-type MAY include a MIME-type parameter of `fhirVersion` as described in the [FHIR specification](https://hl7.org/fhir/http.html#version-parameter) to indicate which version of FHIR the resources in the Bulk Data files are based on. When omitted, defaults to `application/fhir+ndjson` (Newline Delimited JSON) with a version of FHIR determined by the Data Consumer. All of the resources in a submission SHALL use the same version of FHIR.
    """
  * type = #string

* parameter[+]
  * name = #fhirBaseUrl
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Base url to be used by the Data Consumer when resolving relative references in the submitted resources. When the `manifestUrl` parameter is populated, this parameter SHALL be populated.
    """
  * type = #url

* parameter[+]
  * name = #fileRequestHeader
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    HTTP headers that the Data Consumer should use when requesting a data file from the Data Provider.
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
  * max = "*"
  * documentation = """
    Location that a Data Consumer can use to obtain the information needed to retrieve files protected using OAuth 2.0. The url SHALL be the path to a [FHIR Authorization Endpoint and Capabilities Discovery file](https://hl7.org/fhir/smart-app-launch/conformance.html#using-well-known) or another [OAuth 2.0 Protected Resource Metadata file](https://datatracker.ietf.org/doc/rfc9728/) that is registered in the [IANA Well-Known URIs Registry](https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml).
    """
  * type = #url

* parameter[+]
  * name = #fileEncryptionKey
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Encryption key information for the Data Consumer to decrypt retrieved data files from the Data Provider.
    """
  * part[+]
    * name = #coding
    * use = #in
    * min = 0
    * max = "1"
    * documentation = """
      If omitted, defaults to a system of `http://hl7.org/fhir/uv/bulkdata/ValueSet/file-encryption-type` and code of `jwe`.
      """
    * type = #Coding
  * part[+]
    * name = #value
    * use = #in
    * min = 1
    * max = "1"
    * documentation = """
      For the system of `file-encryption-type` and code of `jwe`, populate with the JSON Web Encryption structure to deliver a Content Encryption Key for the Data Consumer to decrypt retrieved data files from the Data Provider.
      """
    * type = #string

* parameter[+]
  * name = #metadata
  * use = #in
  * min = 0
  * max = "*"
  * documentation = """
    Child parameters can be added under this parameter to pass pre-coordinated data relevant to the submission from the Data Provider to the Data Consumer. Each child parameter name SHALL be an absolute URL. Specific child parameters are defined in implementation guides for particular use cases.
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
    Child parameters can be added under this parameter to pass pre-coordinated options relevant to how the data will be processed from the Data Provider to the Data Consumer. For example, a Data Consumer may allow the Data Provider to specify whether or not existing data should be replaced with the data in the submission. Each child parameter name SHALL be an absolute URL. Specific child parameters are defined in implementation guides for particular use cases.
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
