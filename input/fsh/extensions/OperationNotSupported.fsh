Extension: OperationNotSupported
Id: operation-not-supported
Title: "Operation Not Supported"
Description: """
  Extension used in a CapabilityStatement to indicate that the parent resource type or search parameter is not supported for use in a bulk data export operation. For example, the following extension would indicate that the `AllergyIntolerance.clinical-status` search parameter may not be used in a `_typeFilter` parameter on this server.
  ```
    "searchParam": [{
      "name": "clinical-status",
      "type": "token",
      "extension": [{
        "url": "http://hl7.org/fhir/uv/bulkdata/Extension/operation-not-supported",
        "valueCanonical": "http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data"
      }]
    }]
  ```
"""
Context: "CapabilityStatement.rest.resource | CapabilityStatement.rest.resource.searchParam"
* value[x] only canonical
  * ^short = "Canonical URL for unsupported operation"