RuleSet: AsyncParam_outputFormat
* parameter[+]
  * name = #_outputFormat
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is recommended for a server, optional for a client.

    The format for the generated bulk data files. Defaults to `application/fhir+ndjson`. Currently, [NDJSON](http://ndjson.org/) SHALL be supported, though servers MAY also support other output formats. Servers SHALL support the full content type of `application/fhir+ndjson` as well as abbreviated representations including `application/ndjson` and `ndjson`.

    For request types where the server supports either the FHIR Asynchronous Bulk Interaction Pattern or the [Asynchronous Interaction Request Pattern](https://hl7.org/fhir/async-bundle.html), requests that include the `_outputFormat` parameter SHALL trigger the FHIR Asynchronous Bulk Interaction Pattern.
    """
  * type = #string

RuleSet: AsyncParam_minimumFileSize
* parameter[+]
  * name = #_minimumFileSize
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a server, optional for a client.

    Specifies the minimum size in bytes for generated NDJSON files. The value SHALL be a positive integer. If a server supports this parameter, it SHOULD construct files that meet or exceed this size unless doing so would violate the `_maximumFileSize` constraint.
    """
  * type = #positiveInt

RuleSet: AsyncParam_maximumFileSize
* parameter[+]
  * name = #_maximumFileSize
  * use = #in
  * min = 0
  * max = "1"
  * documentation = """
    Support is optional for a server, optional for a client.

    Specifies the maximum size in bytes for generated NDJSON files. The value SHALL be a positive integer and SHALL be greater than `_minimumFileSize` if both are specified. If a server supports this parameter, it SHALL construct files that do not exceed this size. The server MAY use a lower internal maximum.
    """
  * type = #positiveInt
