Instance: ExportErrorOutcomeExample
InstanceOf: OperationOutcome
Title: "Export Error OperationOutcome Example"
Description: "Example OperationOutcome returned in the body of an error status response for a bulk data export."
Usage: #example
* id = "export-error-operationoutcome-example"
* issue[0].severity = #error
* issue[0].code = #processing
* issue[0].details.text = "An internal timeout has occurred"
