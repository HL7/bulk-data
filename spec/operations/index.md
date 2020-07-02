---
title: "FHIR Bulk Data Access (Flat FHIR): Operations"
layout: default
---

## OperationDefinitions defined for this Guide
These OperationDefinitions have been defined for this implementation guide.

* [Export: export any data from a FHIR server](../OperationDefinition-export.html)
* [Patient Export: export patient data from a FHIR server](../OperationDefinition-patient-export.html)
* [Group Export: export data for groups of patients from a FHIR server](../OperationDefinition-group-export.html)

To declare conformance with this IG, a server should include the following URL in its own `CapabilityStatement.instantiates`: <a href="../CapabilityStatement-bulk-data.htm">http://www.hl7.org/fhir/bulk-data/CapabilityStatement-bulk-data|1.0.1</a>