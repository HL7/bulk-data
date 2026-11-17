CodeSystem: IncludeAssociatedDataCodeSystem
Id: include-associated-data
Title: "Include Associated Data Code System"
Description: "Metadata inclusion options for Bulk Data Access Export Operation includeAssociatedData parameter"
* ^status = #active
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 5
* ^experimental = false
* ^jurisdiction = $m49.htm#001 "World"
* ^caseSensitive = true
* ^valueSet = Canonical(IncludeAssociatedDataValueSet)
* ^content = #complete
* #LatestProvenanceResources "LatestProvenanceResources" "Export will include the most recent Provenance resource associated with each non-Provenance resource being returned, as identified by `Provenance.target`. Does not exclude Provenance resources that would otherwise be returned."
* #RelevantProvenanceResources "RelevantProvenanceResources" "Export will include all available Provenance resources associated with each non-Provenance resource being returned, as identified by `Provenance.target`. Does not exclude Provenance resources that would otherwise be returned."
