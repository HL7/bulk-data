Instance: bulk-submit-status
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-submit-status"
* version = "1.0.0"
* name = "BulkSubmitStatus"
* title = "FHIR Bulk Data Submit Status"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 2
* kind = #operation
* affectsState = true
* date = "2025-01-27"
* jurisdiction = $m49.htm#001 "World"
* description = """
    This operation receives status updates about the submission after a Data Provider has kicked off a Bulk Submit operation. For example, the Data Consumer may indicate files it was unable to retrieve, resources that failed validation, or resources that could not be merged into an existing data set. The Data Consumer may also return processed data such as computed quality measures or de-identified versions of the submitted data. The Data Provider receives a `202 Accepted` response with a `Content-Location` header and then polls that URL according to the [FHIR Asynchronous Bulk Interaction Pattern](async.html).
    """
* code = #bulk-submit-status
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
  * name = #_outputFormat
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    The format for the generated bulk data files used to return OperationOutcome resources related to the submission status and, when applicable, other resources. Servers SHALL support ndjson, and MAY support other output formats. Servers SHALL support the full content type of `application/fhir+ndjson` as well as abbreviated representations including `application/ndjson` and `ndjson`. Defaults to `application/fhir+ndjson`.
    """
  * type = #string
