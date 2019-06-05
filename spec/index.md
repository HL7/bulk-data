---
title: FHIR Bulk Data Access (Flat FHIR)
layout: default
---

Providers and organizations accountable for managing the health of populations often need to efficiently access large volumes of information on a group of individuals. For example, a health system may want to periodically retrieve updated clinical data from an EHR to a research database, a provider may want to send clinical data on a roster of patients to their ACO to calculate quality measures, or an EHR may want to access claims data to close gaps in care. In most cases, access to these bulk-data exports is pre-authorized between the data holder and the data requester. The data exchange involves extracting a specific subset of fields from the source system, mapping the fields into a structured file format like CSV, and persisting the files in a server from which the requester can then download them into the target system. This multi-step process increases the cost of integration projects and can act as a counter-incentive to data liquidity.

Existing FHIR APIs work well for accessing small amounts of data, but large exports can require hundreds of thousands of requests. These draft specifications outline a standardized, FHIR based approach for exporting bulk data from a FHIR server to a pre-authorized client.

## Use Cases

These specifications are designed to support sharing any data that can be represented in FHIR. This means they should be useful for such diverse systems as:

* "Native" FHIR servers that store FHIR resources directly
* EHR systems and population health tools implementing FHIR as an interoperability layer
* Financial systems implementing FHIR as an interoperability layer

#### Common Clinical Data Set
*Applies to: EHR systems that support the Common Clinical Data Set (or, looking ahead, the US Core Data for Interoperability).*

This use case exports all resources needed for the Common Clinical Data Set, as profiled by Argonaut. For a full list of these resources and profiles, see http://www.fhir.org/guides/argonaut/r2/profiles.html.

#### Common Financial Data Set
*Applies to: Financial systems that support FHIR-based interoperability.*

This use case exports all resources needed to convey a patient's healththcare financial history, including Patient, ExplanationOfBenefit, Coverage, and Claim. While FHIR profiles are still being developed and standardized, see https://bluebutton.cms.gov/developers/#core-resources for a full-fledged example.

## Resources
* [Overview Presentation](https://docs.google.com/presentation/d/14ZHmam9hwz6-SsCG1YqUIQnJ56bvSqEatebltgEVR6c/edit?usp=sharing)
* [Client and Server Implementations](https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/implementations.md)
* [Discussion Group (FHIR Zulip "Bulk Data" Track)](https://chat.fhir.org/#narrow/stream/bulk.20data)
* [Argonaut Project: Bulk Data Export Security Risk Assessment Report](https://github.com/smart-on-fhir/fhir-bulk-data-docs/raw/9c5a9dcdfcd7b986f59a102bc2b4616552fed3e4/security-risk-assessment-report.pdf)
