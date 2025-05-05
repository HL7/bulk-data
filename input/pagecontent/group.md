### Bulk Exporting Data for a Group

The [Group Level Bulk Export Operation](export.html#endpoint---group-of-patients) scopes the data returned in an export to the population defined by a FHIR Group resource on the server. Depending on the capabilities exposed by the server, a client may be able to retrieve a list of the Group resources it has access to, search for Group resource based on their attributes, read the contents of individual Group resources, and perform other FHIR operations such as creating new Groups, adding and removing members from a Group, or deleting previously created Group resources.

### Group Types

When considering Bulk Export use cases, the community has identified three common patterns of group related server capabilities. A server may support one or more of these patterns.

1. Read-only groups:  Cohorts of patients are managed entirely by the server and are exposed to the client as a set of Group FHIR ids for use in a Bulk Export operation. The server may also provide an API to view, list, and/or search for Group resources on the server, but does not offer clients the ability to create, update or delete Group resources. Examples include a roster provided by a payer organization to a provider organization using negotiated data from another system and a list of patients configured using a registry tool in an EHR system. 

2. Member based groups: Cohorts are managed by the client by specifying individual members using a FHIR API with the ability to add and remove members in Group resources, and/or as create and delete Group resources themselves. Depending on the server capabilities exposed, a client may add members based on their FHIR ids or using characteristics such as a subscriber number. Adding Group resources or adding patients to a group may trigger automated or manual approval workflows on the server. Examples include a patient roster managed using the [DaVinci ATR API](https://hl7.org/fhir/us/davinci-atr/) or a Group created with using member FHIR ids located using the FHIR [patient match operation](https://hl7.org/fhir/patient-operation-match.html).

3. Criteria based groups: Cohorts of patients on the server are managed by the client with a FHIR API that includes the ability to define Group resources based on a set of patient characteristics. These characteristics are then used by the server to associate members with the group. Examples would be a client that uses a FHIR API to create a cohort of patients who are assigned to a specific practitioner, or a cohort of patients with a problem list condition of diabetes and a visit in the past month. A group may represent a subset of another "read-only group" or "member based group", and could be point in time snapshot based on membership at the time of creation or dynamically update as new patients meet the specified criteria. The Bulk Cohort API described below represents one approach to defining criteria based groups.

### Bulk Cohort API

Servers supporting the Bulk Data Access IG MAY support the Bulk Cohort API which consists of an asynchronous Group creation REST interaction and a profile on the Group resource. The intent is to support the creation of characteristic based cohorts using coarse-grained filters to more efficiently export data on sets of patients from a source system. Post export, the client can use the FHIR resources returned for these cohorts for finer grained filtering to support use cases such as measure calculation or analytics that may necessitate more complex filter criteria.

#### REST Interactions

When the Bulk Cohort API is supported, the server SHALL accept FHIR Group create requests that use the [FHIR Asynchronous Interaction Request](https://hl7.org/fhir/async-bundle.html) pattern and provide a valid FHIR Group resource that complies with the [Bulk Cohort Group Profile](#group-profile). Servers MAY also accept synchronous FHIR Group create requests, but since not all servers can create groups in this way (for example, some systems require a manual group approval step), clients should not expect this to be universally available. After group creation, a server MAY subsequently make the new Group resource available to authorized clients or MAY reject resource creation request and returning a relevant error. Servers SHOULD support read, search, delete, and Bulk Export operations on created Group resources, and SHOULD support the `name` search parameter in search requests for these resources. Servers MAY support other FHIR REST API operations and other search parameters. 

Servers MAY support Group update requests. When update requests are supported, servers SHALL accept update requests that use the [FHIR Asynchronous Interaction Request](https://hl7.org/fhir/async-bundle.html) pattern and MAY accept synchronous update requests.

#### Group Profile

**[Full Bulk Cohort Profile](StructureDefinition-bulk-cohort-group.html)**


##### Key Elements

{% sqlToData elements 
	WITH elements AS (
		SELECT 
		element.parent,
		MAX(CASE WHEN element.key = 'id' THEN atom END) AS el_id,
		MAX(CASE WHEN element.key = 'definition' THEN atom END) AS el_def,
		MAX(CASE WHEN element.key = 'path' THEN atom END) AS el_path,
		MAX(CASE WHEN element.key = 'min' THEN atom END) AS el_min,	
		MAX(CASE WHEN element.key = 'max' THEN atom END) AS el_max	
		FROM Resources,
			json_tree(Resources.Json, '$.snapshot.element') AS element
		WHERE Resources.Id = 'bulk-cohort-group'
		GROUP BY 1
	)
	SELECT *,
	el_min || '..' || el_max AS cardinality
	FROM elements
%}

{% assign element = elements | find: 'el_id', 'Group.member' %}
{{ '<br/><code>member</code> (' | append: element.cardinality | append: ')<br/>' | append: element.el_def | markdownify }}

{% assign element = elements | find: 'el_id', 'Group.modifierExtension' %}
{{ '<br/><code>member-filter</code> ModifierExtension (' | append: element.cardinality | append: ')<br/>' | append: element.el_def | markdownify }}

{% assign element = elements | find: 'el_id', 'Group.extension' %}
{{ '<br/><code>members-refreshed</code> Extension (' | append: element.cardinality | append: ')<br/>' | append: element.el_def | markdownify }}

{% assign element = elements | find: 'el_id', 'Group.type' %}
{{ '<br/><code>type</code> (' | append: element.cardinality | append: ')<br/>' | append: element.el_def | markdownify }}

{% assign element = elements | find: 'el_id', 'Group.name' %}
{{ '<br/><code>name</code> (' | append: element.cardinality | append: ')<br/>' | append: element.el_def | markdownify }}

{% assign element = elements | find: 'el_id', 'Group.characteristic' %}
{{ '<br/><code>characteristic</code> (' | append: element.cardinality | append: ')<br/>' | append: element.el_def | markdownify }}

{% assign element = elements | find: 'el_id', 'Group.actual' %}
{{ '<br/><code>actual</code> (' | append: element.cardinality | append: ')<br/>' | append: element.el_def | markdownify }}

#### Example

Group with plan members filtered to patients with diabetes on their problem list and an ambulatory encounter in January 2024.

{% fragment Group/BulkCohortGroupExample JSON ELIDE:id|meta|text %}

[View Example](Group-BulkCohortGroupExample.json.html)

### Server Capability Documentation
To provide clarity to developers on which capabilities are implemented in a particular server, server providers SHALL ensure that their Capability Statement accurately reflects the Bulk Cohort profile as a `rest.resource.supportedProfile` of Group.  Server providers SHOULD also ensure that their documentation addresses when and how often are Bulk Cohort group membership is updated and which search parameters are supported in `member-filter` expressions.
