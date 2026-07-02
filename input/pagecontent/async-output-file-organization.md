##### Bulk Data Output File Organization

Output files may be organized by resource type, or by instances of a resource type specified in the `organizeOutputBy` kickoff parameter.

When the `organizeOutputBy` kickoff parameter is not populated, each output file SHALL contain resources of only one type, and a {{ bulk_server_role }} MAY create more than one file for each resource type returned. The number of resources contained in a file MAY vary between {{ bulk_server_role }}s and files.

When the `organizeOutputBy` kickoff parameter is populated with a resource type, the output files SHALL be populated with blocks consisting of a header `Parameters` resource containing a parameter named `header` with a reference to a resource of the type in the kickoff parameter, followed by the resource referenced in this header and resources that reference the resource referenced in the header (together a "resource block"). Each output file MAY contain multiple resource blocks and, when possible, a single resource's block SHOULD NOT be split across files. If a resource block does span more than one file, the header SHALL be repeated at the start of each file where the block continues, and the association between these files SHALL be documented in the manifest using the `continuesInFile` field in the relevant `output` array items.

Resources that would otherwise be included in the export, but do not have references to the resource type specified in the `organizeOutputBy` parameter, MAY be included in resource blocks that contain resources they reference, MAY be repeated in every resource block, or MAY be omitted from the export.

<div class="stu-note">
When the <code>organizeOutputBy</code> parameter is set to <code>Patient</code>, {{ bulk_server_role }}s SHOULD use the <a href="https://www.hl7.org/fhir/compartmentdefinition-patient.html">Patient Compartment Definition</a> to determine a base set of related resources to include in a resource block, though other resources may also be included.

For other resource types, we are soliciting feedback on the best approach for documenting the set of resources in a resource block. Implementation Guides MAY reference a <a href="https://www.hl7.org/fhir/compartmentdefinition.html">Compartment Definition</a>, populate a <a href="https://www.hl7.org/fhir/graphdefinition.html">GraphDefinition Resource</a>, include narrative text, or use another approach.
</div>

Example NDJSON file when the `organizeOutputBy` parameter in the kickoff request is not populated:

```js
{"id":"p-1","resourceType":"Patient", "name":[{"given":["Brenda"],"family":"Jackson"}],"gender":"female", ...}
{"id":"p-2","resourceType":"Patient", "name":[{"given":["Bram"],"family":"Sandeep"}],"gender":"male", ...}
{"id":"p-3","resourceType":"Patient", "name":[{"given":["Sandy"],"family":"Hamlin"}],"gender":"female", ...}
{...}
```

<a name="organize-output-by-file-example"></a>

Example NDJSON file when the `organizeOutputBy` parameter in the kickoff request is set to `Patient`:

```js
{"resourceType": "Parameters", "parameter": [{"name": "header", "valueReference": {"reference": "Patient/p-1"}}]}
{"id": "p-1", "resourceType": "Patient", ...}
{"id": "c-1", "resourceType": "Condition", "subject":{"reference": "Patient/p-1"}, ...}
{"id": "o-1", "resourceType": "Observation", "subject":{"reference": "Patient/p-1"}, ...}
{...}
{"resourceType": "Parameters", "parameter": [{"name": "header", "valueReference": {"reference": "Patient/p-2"}}]}
{"id": "p-2", "resourceType": "Patient", ...}
{"id": "c-101", "resourceType": "Condition", "subject":{"reference": "Patient/p-2"}, ...}
{"id": "o-102", "resourceType": "Observation", "subject":{"reference": "Patient/p-2"}, ...}
{...}
```
