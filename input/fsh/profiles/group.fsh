ValueSet: GroupTypeSubset
Id: group-type-subset
Title: "Person and Practitioner from GroupType Value Set"
Description: "Valuset to constrain the type element in a Group to person, practitioner and device"
* ^experimental = false
* ^jurisdiction = http://unstats.un.org/unsd/methods/m49/m49.htm#001 "World"
* ^immutable = true
* http://hl7.org/fhir/group-type#person
* http://hl7.org/fhir/group-type#practitioner
* http://hl7.org/fhir/group-type#device

Extension: MemberFilter
Id: member-filter
Title: "Member Filter"
Description: """
  Extension to define the population of the group using FHIR REST API parameters. For example, the following extension would limit the population of the group to patients with an ambulatory encounter in January 2024:
  ```
  "modifierExtension" : [{
    "url" : "http://hl7.org/fhir/uv/bulkdata/StructureDefinition/member-filter",
    "valueExpression" : {
      "language" : "application/x-fhir-query",
      "expression" : "Encounter?class=http://terminology.hl7.org/CodeSystem/v3-ActCode|AMB&date=ge2024-01-01&date=le2024-01-31"
    }
  }]
  ```
"""
Context: Group
* . ^isModifier = true
* . ^isModifierReason = "Filters members of group to a subset"
* value[x] only Expression

Extension: MembersRefreshed
Id: members-refreshed
Title: "Members Refreshed"
Description: """
  Extension used by a server to indicate to a client when the members in a dynamic group were last updated. For example, the following extension would indicate that the group members were last updated January 1st 2024:
  ```
  "Extension" : [{
    "url" : "http://hl7.org/fhir/uv/bulkdata/StructureDefinition/members-refreshed",
    "valueDateTime" : "2024-01-01T13:28:17-05:00"
  }]
  ```
"""
Context: Group
* value[x] only dateTime


Profile: BulkCohortGroup
Parent: Group
Id: bulk-cohort-group
Title: "Bulk Cohort Group"
Description: "Group that provides characteristic based cohorts through coarse-grained, REST search expression based filters to support constraining bulk export requests"
* type from GroupTypeSubset (required)
  * ^definition = """
    A client SHALL populate this element with `person` when creating a group of Patient resources, `practitioner` when creating a group of Practitioner resources, or `device` when creating a group of Device resources.
    """
* member
  * ^definition = """
    A server MAY support the inclusion of one or more `member` elements that contain an `entity` element with a reference to a `Patient` resource, `Practitioner` resource, `Device` resource, or a `Group` resource that is a group of one of these resource types. When members are provided, the expression in the `member-filter` extension for the Group SHALL only be applied to the referenced resources and the compartments of the referenced resources, and the resources and compartments of the members of any referenced Groups. When members are not provided and the Group's `type` element is set to `person`, the expression in the `member-filter` extension SHALL be applied to all of the Patient resources and Patient compartments the client is authorized to access. When members are not provided and the Group's `type` element is set to `practitioner`, the expression in the `member-filter` extension SHALL be applied to all of the Practitioner resources and Practitioner compartments the client is authorized to access. When members are not provided and the Group's `type` element is set to `device`, the expression in the `member-filter` extension SHALL be applied to all of the Device resources and Device compartments the client is authorized to access.
    """
  * entity only Reference (Patient or Practitioner or Device or Group)

* modifierExtension contains MemberFilter named member-filter 1..*
  * ^short = "Filter for members of this group"
  * ^definition = """
    A server SHALL support the inclusion of one or more `member-filter` modifier extensions containing a `valueExpression` with a language of `application/x-fhir-query` and an `expression` populated with a FHIR REST API query, and SHALL support REST queries for one or more of the Patient, Practitioner, or Device resource types. For supported resource types, the server SHALL also support querying the resources in that resource type's compartment. If multiple `member-filter` extensions are provided, servers SHALL filter the group to only include resources that meet the conditions in all of the expressions or resources that have resources in their compartments that meet the conditions in all of the expressions. A server MAY also support other expression languages such as `text/cql`. When more than one language is supported by a server a client SHALL use a single language type for all of the member-filter expressions included in a single Group.

    FHIR [search result parameters](https://www.hl7.org/fhir/search.html#modifyingresults) (such as _sort, _include, and _elements) SHALL NOT be used as `member-filter` criteria. Additionally, a query in the `member-filter` parameter SHALL have the search context of a single FHIR Resource Type. The contexts "all resource types" and "a specified compartment" are not allowed. Clients should consult the server's capability statement to identify supported search parameters. Servers SHALL reject Group creation requests that include unsupported search parameters in a `member-filter` expression. Implementation guides that reference the Bulk Cohort API, should specify required search parameters must be supported for their use case. Other implementations guides that incorporate the Bulk Export operation MAY provide a set of core search parameters that servers implementing the guide need to support.
    """
* extension contains MembersRefreshed named members-refreshed 0..1
  * ^short = "when membership in this group was updated"
  * ^definition = """
    If a group's membership is calculated periodically from the `member-filter` criteria, a server SHALL populate a `valueDateTime` with the date the group's membership was last updated. When a `date` element is populated for the Group, the `valueDateTime` element SHALL NOT be later than the date in that element, but may be the same datetime or an earlier datetime. If members are calculated dynamically for the group (for example, when a Bulk Export operation is kicked off) this value SHALL be omitted. The server's refresh cycle capabilities and relevant configuration options SHOULD be described in the server's documentation.
    """
* name 1..1
* characteristic 0..0
  * ^short = "This element is not used in groups complying with this profile"
  * ^definition = "This element is not used in groups complying with this profile"

* actual
  * ^short = "True if the member element is populated, otherwise false."
  * ^definition = "True if the member element is populated, otherwise false."

Instance: BulkCohortGroupExample
InstanceOf: BulkCohortGroup
Title: "Bulk Cohort Group Example"
Description: "Blue cross plan member group with members filtered to patients that have an active diagnosis of diabetes on their problem list and an ambulatory encounter in January 2024"
Usage: #example
* meta.extension[0].url = "http://hl7.org/fhir/StructureDefinition/instance-name"
* meta.extension[0].valueString = "Bulk Cohort Group Profile Example"
* meta.extension[1].url = "http://hl7.org/fhir/StructureDefinition/instance-description"
* meta.extension[1].valueMarkdown = "Blue cross plan member group with members filtered to patients that have an active diagnosis of diabetes on their problem list and an ambulatory encounter in January 2024"
* name = "DM Dx and Jan. 2024 Ambulatory Encounter"
* member.entity = Reference(http://example.org/fhir/Group/blue-cross-members)
* extension[members-refreshed].valueDateTime = "2024-08-22T10:00:00Z"
* modifierExtension[member-filter][0].valueExpression.language = #application/x-fhir-query
* modifierExtension[member-filter][0].valueExpression.expression = "Condition?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item&clinical-status=http://terminology.hl7.org/CodeSystem/condition-clinical|active&code=http://hl7.org/fhir/sid/icd-10-cm|E11.9"
* modifierExtension[member-filter][1].valueExpression.language = #application/x-fhir-query
* modifierExtension[member-filter][1].valueExpression.expression = "Encounter?class=http://terminology.hl7.org/CodeSystem/v3-ActCode|AMB&date=ge2024-01-01&date=le2024-01-31"
* type = #person
* actual = true