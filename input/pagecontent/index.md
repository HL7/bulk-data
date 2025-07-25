Providers and organizations accountable for managing the health of populations often need to efficiently access large volumes of information on a group of individuals. For example, a health system may want to periodically retrieve updated clinical data from an EHR to a research database, a provider may want to send clinical data on a roster of patients to their ACO to calculate quality measures, or an EHR may want to display claims data to help close gaps in care. The data exchange often involves extracting a specific subset of fields from the source system, mapping the fields into a structured file format like CSV, and persisting the files in a server from which the requester can then download them into the target system. This multi-step process increases the cost of integration projects and can act as a counter-incentive to data liquidity.

Existing FHIR APIs work well for accessing small amounts of data, but large exports can require hundreds of thousands of requests. This implementation guide defines a standardized, FHIR based approach for exporting bulk data from a FHIR server to a pre-authorized client.

### Conformance
To declare conformance with this IG, a server should include the following URL in its `CapabilityStatement.instantiates`: `http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data`


### Use Cases

This implementation guide is designed to support sharing any data that can be represented in FHIR. This means that the IG should be useful for such diverse systems as:

* "Native" FHIR servers that store FHIR resources directly
* EHR systems and population health tools implementing FHIR as an interoperability layer
* Financial systems implementing FHIR as an interoperability layer

#### US Core Data for Interoperability
*Applies to: EHR systems that support the US Core Data for Interoperability.*

This use case exports all resources needed for the [US Core Data for Interoperability](https://www.healthit.gov/isa/united-states-core-data-interoperability-uscdi), as profiled by the [HL7 Argonaut FHIR Accelerator](https://confluence.hl7.org/display/AP/Argonaut+Project+Home). For a full list of these resources and profiles, see [http://www.hl7.org/fhir/us/core/](http://www.hl7.org/fhir/us/core/).

#### Common Financial Data Set
*Applies to: Financial systems that support FHIR-based interoperability.*

This use case exports all resources needed to convey a patient's healthcare financial history, including Patient, ExplanationOfBenefit, Coverage, and Claim. While FHIR profiles are still being developed and standardized, see [https://bluebutton.cms.gov/developers/#core-resources](https://bluebutton.cms.gov/developers/#core-resources) for a full-fledged example.

#### Additional Use Cases
* Terminology data - export CodeSystem and ValueSet resources from a terminology server
* Provider data - export a system's Practitioner, Location, and Organization lists
* Public health surveillance that does not require real-time exchange of data, such as aggregate situational awareness data reporting
* Electronic Case Reporting (data from initial export may be filtered or summarized before submitting)

### Implementation Guide Details
The [Bulk Data Access ImplementationGuide Resource](ImplementationGuide-hl7.fhir.uv.bulkdata.html) defines the technical details of this publication, including dependencies and  publishing parameters.

### Additional Documentation
* [Overview Presentation](https://docs.google.com/presentation/d/14ZHmam9hwz6-SsCG1YqUIQnJ56bvSqEatebltgEVR6c/edit?usp=sharing)
* [Discussion Group (FHIR Zulip "Bulk Data" Track)](https://chat.fhir.org/#narrow/stream/bulk.20data)
* [Argonaut Project: Bulk Data Export Security Risk Assessment Report](security-risk-assessment-report.pdf)
* [Implementation Guide Change Log](changes.html)