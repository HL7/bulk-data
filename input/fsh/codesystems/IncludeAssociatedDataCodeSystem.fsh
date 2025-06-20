CodeSystem: IncludeAssociatedDataCodeSystem
Id: include-associated-data
Title: "Include Associated Data Code System"
Description: "Metadata inclusion options for Bulk Data Access Export Operation includeAssociatedData parameter"
* ^version = "2.0.0"
* ^status = #active
* ^date = "2021-07-29"
* ^experimental = false
* ^jurisdiction = $m49.htm#001 "World"
* ^caseSensitive = true
* ^valueSet = Canonical(IncludeAssociatedDataValueSet)
* ^content = #complete
* #LatestProvenanceResources "LatestProvenanceResources" "Export will include the most recent Provenance resources associated with each of the non-provenance resources being returned. Other Provenance resources will not be returned."
* #RelevantProvenanceResources "RelevantProvenanceResources" "Export will include all Provenance resources associated with each of the non-provenance resources being returned."