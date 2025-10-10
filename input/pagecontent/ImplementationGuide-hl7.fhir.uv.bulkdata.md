{% assign igID  = site.data.fhir.igId  %}
{% assign IG =  "ImplementationGuide/" | append: igID %}

|||
|---|---|
|*Official URL*: {{ site.data.resources[IG].url }}|*Version*: {{ site.data.resources[IG].version }}|
|*NPM package name*: {{ site.data.fhir.packageId }}|*ComputableName*: {{ site.data.resources[IG].name }}|
{:.grid}

{{ site.data.resources[IG].description }}

- [XML](ImplementationGuide-{{igID}}.xml)
- [JSON](ImplementationGuide-{{igID}}.json)

### Cross Version Analysis

{% capture cross-version-analysis %}{% include cross-version-analysis-en.xhtml %}{% endcapture %}{{ cross-version-analysis | remove: '<p>' | remove: '</p>'}}

### IG Dependencies

This IG Contains the following dependencies on other IGs.

{% include dependency-table-en.xhtml %}

### Global Profiles

{% include globals-table-en.xhtml %}

### Copyrights

{% capture ip-statement %}{% include ip-statements-en.xhtml %}{% endcapture %}

{{ ip-statement | remove: '<p>' | remove: '</p>'}}