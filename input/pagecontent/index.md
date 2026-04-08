Organizations that manage populations often need to exchange large FHIR datasets. Examples include pulling a cohort from an EHR for analytics, sending a pre-arranged package of data to a payer or regulator, or publishing reference data such as provider directories and schedules. Standard FHIR REST APIs work well for interactive and transaction-scale use, but resource-by-resource exchange becomes expensive and operationally brittle when the job involves thousands or millions of resources.

This implementation guide defines a family of FHIR-based bulk operations that standardize how large datasets are requested, delivered, monitored, and reused. Instead of relying on custom CSV extracts and one-off file transfer workflows, these operations use consistent manifest structures, asynchronous processing, and security patterns that can be applied across many implementations. 

The operations are applicable to any data that can be represented in FHIR, and may be implemented in "native" FHIR servers that store FHIR resources directly as well as systems that implement FHIR as an interoperability layer (as is often the case with EHR systems and data warehouse platforms).

The scope of this document does NOT include:

* A legal framework for sharing data between partners, such as Business Associate Agreements, Service Level Agreements, and Data Use Agreements, though these may be required in many use cases.
* Real-time data exchange
* Data transformations, validation or processing that may be needed by the Data Consumer
* Patient matching (although identifiers may be included in the FHIR resources being transmitted)

### Example Use Cases

- A healthcare organization submitting data to a regulatory agency to meet a reporting requirement
- A healthcare organization sending clinical data to a payer organization to support a quality measurement calculation
- A payer organization sharing data on claim status with a healthcare organization
- A healthcare organization moving data from a clinical system onto a standalone FHIR server to consolidate data from multiple systems in order to run analytic queries
- An organization providing FHIR data to an internal or external service to process the data for de-identification or other transformation
- An organization sharing a pre-defined dataset from a clinical system with another application, such as a care management tool


### Choosing a Bulk Operation

Bulk Data defines three operations. Each fits a different relationship between the system that holds the data (Data Provider) and the system that needs it (Data Consumer).

**[Bulk Export](export.html)** — The consumer pulls data from a provider on demand. The consumer controls what comes back by optionally choosing the cohort, resource types, filters, data elements, and time window. Use this operation when a system needs to retrieve data from a trusted source and shape the request to its own needs — for example, a research data warehouse exporting clinical data from an EHR or a payer exporting claims-relevant records.

**[Bulk Submit](submit.html)** — The provider pushes a pre-coordinated dataset to a specific recipient. Both sides agree in advance on what the submission contains, and the recipient can acknowledge processing, report issues, or return derived artifacts through the in-band Bulk Submit Status channel. Use this when the sender already knows what must be delivered and the receiver needs to close the loop — for example, submitting required clinical data to a payer, regulator, or processing service.

**[Bulk Publish](publish.html)** — The provider posts a dataset for any number of consumers to retrieve via ordinary HTTP. The provider decides what is published; consumers discover and cache it using standard HTTP semantics. Use this when the same relatively static dataset serves many downstream systems — for example, publishing a provider directory, formulary, or scheduling data.

Multiple operations can be used to address a single use case. For example, an intermediary might use Bulk Export to retrieve data from one system, transform it, and then use Bulk Submit to deliver the transformed version to another system.

<style>
  .operations-comparison-intro + table {
    width: 100%;
    margin: 1rem 0 1.5rem;
  }

  .operations-comparison-intro + table th,
  .operations-comparison-intro + table td {
    padding: 0.5rem 0.75rem;
    border: 1px solid #dddddd;
    vertical-align: top;
  }

  .operations-comparison-intro + table th,
  .operations-comparison-intro + table tr > :first-child {
    background: #f5f5f5;
    font-weight: bold;
  }

</style>

<p class="operations-comparison-intro">Key distinctions between the operations:</p>

|                   | Bulk Export                                                        | Bulk Submit                                               | Bulk Publish                                                        |
|----------------------------|--------------------------------------------------------------------|-----------------------------------------------------------|---------------------------------------------------------------------|
| Cohort and data elements  | **Recipient specifies**                                           | Provider defines                                          | Provider defines                                                    |
| Kick-off workflow         | Recipient pull                                                    | **Provider push**                                         | Recipient pull                                                      |
| Cardinality               | One provider to one recipient                                     | One provider to one recipient                             | **One provider to many recipients**                                 |
| Feedback channel          | Out of band                                                       | **In band**                                               | Out of band                                                         |

### Representing Cohorts

Many bulk workflows are applicable to a specific cohort of patients rather than all patients in a system. These cohorts can be represented and managed as FHIR `Group` resources. For example, a payer roster, research cohort, care management panel, quality-measure population, recently discharged patients, or another recurring population that needs to be exchanged over time can be modeled as a FHIR group. As described on [the Group page](group.html), implementations may expose read-only groups managed by the Data Provider, member-based groups managed by the Data Consumer, or criteria-based groups whose membership is computed from characteristics. Some Data Providers may also support the Bulk Cohort API described in this guide for asynchronous creation of characteristic-based cohorts by a Data Consumer.

### Conformance and Publication

To declare conformance with this IG, a server should include the following URL in its `CapabilityStatement.instantiates`: `http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data`.

The [Bulk Data Access Implementation Guide Resource](ImplementationGuide-hl7.fhir.uv.bulkdata.html) defines the technical details of this publication, including dependencies and publishing parameters.

### Underlying Standards

* [HL7 FHIR](https://www.hl7.org/fhir/)
* [Newline-delimited JSON](https://github.com/ndjson/ndjson-spec)
* [RFC5246, Transport Layer Security (TLS) Protocol Version 1.2](https://tools.ietf.org/html/rfc5246)
* [RFC6749, The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
* [RFC6750, The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750)
* [RFC7159, The JavaScript Object Notation (JSON) Data Interchange Format](https://tools.ietf.org/html/rfc7159)
* [RFC7240, Prefer Header for HTTP](https://tools.ietf.org/html/rfc7240)

### Terminology

This profile inherits terminology from the standards referenced above.
The key words "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in [RFC2119](https://tools.ietf.org/html/rfc2119).

### Datasets

Common datasets to exchanged through bulk operations include:

* Clinical data such as the [US Core Data for Interoperability](https://www.healthit.gov/isa/united-states-core-data-interoperability-uscdi), as profiled by  in [US Core](http://www.hl7.org/fhir/us/core/)
* Financial data such as the Patient, ExplanationOfBenefit, Coverage, and Claim resources profiled in [CMS Blue Button](https://bluebutton.cms.gov)
* Terminology data, such the CodeSystem and ValueSet resources stored in a [FHIR terminology service](https://hl7.org/fhir/terminology-service.html)


### Additional Documentation
* [Discussion Group (FHIR Zulip "Bulk Data" Track)](https://chat.fhir.org/#narrow/stream/bulk.20data)
* [Argonaut Project: Bulk Data Export Security Risk Assessment Report](security-risk-assessment-report.pdf)
* [Implementation Guide Change Log](changes.html)
