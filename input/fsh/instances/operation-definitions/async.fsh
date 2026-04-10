Instance: async
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/async"
* version = "2.0.0"
* name = "AsynchronousBulkInteractionPattern"
* title = "FHIR Asynchronous Bulk Interaction Pattern"
* status = #active
* extension[+].url = $fmm
* extension[=].valueInteger = 5
* kind = #operation
* date = "2026-04-10"
* jurisdiction = $m49.htm#001 "World"
* description = """
    Common kick-off request parameters for operations and defined interactions that implement the [FHIR Asynchronous Bulk Interaction Pattern](async.html). This pattern supports asynchronous generation of large FHIR datasets and is triggered by the `Prefer: respond-async` header on the underlying request.
    """
* code = #async
* system = true
* type = false
* instance = false
* insert AsyncParam_outputFormat
* insert AsyncParam_minimumFileSize
* insert AsyncParam_maximumFileSize
