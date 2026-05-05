ValueSet: SubmissionStatusValueSet
Id: submission-status
Title: "Submission Status Value Set"
Description: "Status codes for the Bulk Data Submit operation `submissionStatus` parameter."
* ^version = "1.0.0"
* ^status = #active
* ^extension[+].url = $fmm
* ^extension[=].valueInteger = 2
* ^date = "2026-05-05"
* ^experimental = false
* ^jurisdiction = $m49.htm#001 "World"
* ^immutable = true
* http://hl7.org/fhir/event-status#in-progress
* http://hl7.org/fhir/event-status#completed
* http://hl7.org/fhir/event-status#stopped
