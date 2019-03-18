---
title: "FHIR Bulk Data Access (Flat FHIR): Operations"
layout: default
---

## OperationDefinitions defined for this Guide
These OperationDefinitions have been defined for this implementation guide.

* [Export: export any data from a FHIR server](#export-export-any-data-from-a-fhir-server)
* [Patient Export: export patient data from a FHIR server](#patient-export-export-patient-data-from-a-fhir-server)
* [Group Export: export data for groups of patients from a FHIR server](#group-export-export-data-for-groups-of-patients-from-a-fhir-server)


### Export: export any data from a FHIR server
`GET [fhir base]/$export`  

Export data from a FHIR server whether or not it is associated with a patient.  

```json
{
  "resourceType": "OperationDefinition",
  "id": "example",
  "text": {
    "status": "generated",
    "div" : "<div>!-- Snipped for Brevity --></div>"
  },
  "url": "http://h7.org/fhir/OperationDefinition/example",
  "version": "1.0.0",
  "name": "FHIR Bulk Data Export - System Level Export",
  "title": "FHIR Bulk Data Export (Flat FHIR) - System Level Export",
  "status": "active",
  "kind": "operation",
  "date": "2019-02-15",
  "publisher": "SMART Health IT",
  "contact": [
    {
      "name": "Ricky Sahu",
      "telecom": [
        {
          "system": "email",
          "value": "ricky@1up.health"
        }
      ]
    },
    {
      "name": "Dan Gottlieb",
      "telecom": [
        {
          "system": "email",
          "value": "daniel.gottlieb@childrens.harvard.edu"
        }
      ]
    },
    {
      "name": "Josh Mandel",
      "telecom": [
        {
          "system": "email",
          "value": "joshua.mandel@childrens.harvard.edu"
        }
      ]
    },
    {
      "name": "Vlad Ignatov",
      "telecom": [
        {
          "system": "email",
          "value": "Vladimir.Ignatov@childrens.harvard.edu"
        }
      ]
    }
  ],
  "description": "Export data from a FHIR server whether or not it is associated with a patient. This supports use cases like backing up a server or exporting terminology data by restricting the resources returned using the _type parameter.",
  "code": "$export",
  "base": "/",
  "system": true,
  "type": false,
  "instance": false,
  "parameter": [
    {
      "name": "_outputFormat",
      "use": "out",
      "min": 0,
      "max": "1",
      "documentation": "The format for the requested bulk data files to be generated. Servers MUST support Newline Delimited JSON, but MAY choose to support additional output formats. Servers MUST accept the full content type of application/fhir+ndjson as well as the abbreviated representations application/ndjson and ndjson. Defaults to application/fhir+ndjson",
      "type": "string"
    },
    {
      "name": "_since",
      "use": "in",
      "min": 0,
      "max": "1",
      "documentation": "Resources updated after this period will be included in the response. ",
      "type": "instant"
    },
    {
      "name": "_type",
      "use": "out",
      "min": 0,
      "max": "1",
      "documentation": "A string of comma-delimited FHIR resource types. Only resources of the specified resource types(s) SHOULD be included in the response. If this parameter is omitted, the server SHOULD return all supported resources within the scope of the client authorization. For non-system-level requests, the Patient Compartment SHOULD be used as a point of reference for recommended resources to be returned as well as other resources outside of the patient compartment that are helpful in interpreting the patient data such as Organization and Practitioner. Resource references MAY be relative URIs with the format <resource type>/<id>, or absolute URIs with the same structure rooted in the base URI for the server from which the export was performed. References will be resolved looking for a resource with the specified type and id within the file set. Note: Implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the Argonaut Implementation Guide",
      "type": "string"
    }
  ]
}
```

### Patient Export: export patient data from a FHIR server

`GET [fhir base]/Patient/$export`  

Export data only associated with patients and their resources.  

```json
{
  "resourceType": "OperationDefinition",
  "id": "example",
  "text": {
    "status": "generated",
    "div" : "<div>!-- Snipped for Brevity --></div>"
  },
  "url": "http://h7.org/fhir/OperationDefinition/example",
  "version": "1.0.0",
  "name": "FHIR Bulk Data Export - System Level Export",
  "title": "FHIR Bulk Data Export (Flat FHIR) - System Level Export",
  "status": "active",
  "kind": "operation",
  "date": "2019-02-15",
  "publisher": "SMART Health IT",
  "contact": [
    {
      "name": "Ricky Sahu",
      "telecom": [
        {
          "system": "email",
          "value": "ricky@1up.health"
        }
      ]
    },
    {
      "name": "Dan Gottlieb",
      "telecom": [
        {
          "system": "email",
          "value": "daniel.gottlieb@childrens.harvard.edu"
        }
      ]
    },
    {
      "name": "Josh Mandel",
      "telecom": [
        {
          "system": "email",
          "value": "joshua.mandel@childrens.harvard.edu"
        }
      ]
    },
    {
      "name": "Vlad Ignatov",
      "telecom": [
        {
          "system": "email",
          "value": "Vladimir.Ignatov@childrens.harvard.edu"
        }
      ]
    }
  ],
  "description": "Export data from a FHIR server for all data associated with patients. This supports use cases like transmitting all data about patients or clinical care between systems.",
  "code": "$export",
  "resource": ["Patient"],
  "system": false,
  "type": true,
  "instance": false,
  "parameter": [
    {
      "name": "_outputFormat",
      "use": "out",
      "min": 0,
      "max": "1",
      "documentation": "The format for the requested bulk data files to be generated. Servers MUST support Newline Delimited JSON, but MAY choose to support additional output formats. Servers MUST accept the full content type of application/fhir+ndjson as well as the abbreviated representations application/ndjson and ndjson. Defaults to application/fhir+ndjson",
      "type": "string"
    },
    {
      "name": "_since",
      "use": "in",
      "min": 0,
      "max": "1",
      "documentation": "Resources updated after this period will be included in the response.",
      "type": "instant"
    },
    {
      "name": "_type",
      "use": "out",
      "min": 0,
      "max": "1",
      "documentation": "A string of comma-delimited FHIR resource types. Only resources of the specified resource types(s) SHOULD be included in the response. If this parameter is omitted, the server SHOULD return all supported resources within the scope of the client authorization. For non-system-level requests, the Patient Compartment SHOULD be used as a point of reference for recommended resources to be returned as well as other resources outside of the patient compartment that are helpful in interpreting the patient data such as Organization and Practitioner. Resource references MAY be relative URIs with the format <resource type>/<id>, or absolute URIs with the same structure rooted in the base URI for the server from which the export was performed. References will be resolved looking for a resource with the specified type and id within the file set. Note: Implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the Argonaut Implementation Guide",
      "type": "string"
    }
  ]
}
```

### Group Export: export data for groups of patients from a FHIR server

`GET [fhir base]/Group/[id]/$export`  

FHIR Operation to obtain data on all patients listed in a single [FHIR Group Resource](https://www.hl7.org/fhir/group.html).  

```json
{
  "resourceType": "OperationDefinition",
  "id": "example",
  "text": {
    "status": "generated",
    "div" : "<div>!-- Snipped for Brevity --></div>"
  },
  "url": "http://h7.org/fhir/OperationDefinition/example",
  "version": "1.0.0",
  "name": "FHIR Bulk Data Export - System Level Export",
  "title": "FHIR Bulk Data Export (Flat FHIR) - System Level Export",
  "status": "active",
  "kind": "operation",
  "date": "2019-02-15",
  "publisher": "SMART Health IT",
  "contact": [
    {
      "name": "Ricky Sahu",
      "telecom": [
        {
          "system": "email",
          "value": "ricky@1up.health"
        }
      ]
    },
    {
      "name": "Dan Gottlieb",
      "telecom": [
        {
          "system": "email",
          "value": "daniel.gottlieb@childrens.harvard.edu"
        }
      ]
    },
    {
      "name": "Josh Mandel",
      "telecom": [
        {
          "system": "email",
          "value": "joshua.mandel@childrens.harvard.edu"
        }
      ]
    },
    {
      "name": "Vlad Ignatov",
      "telecom": [
        {
          "system": "email",
          "value": "Vladimir.Ignatov@childrens.harvard.edu"
        }
      ]
    }
  ],
  "description": "FHIR Operation to obtain data on all patients listed in a single FHIR Group Resource. If a FHIR server supports Group-level data export, it SHOULD support reading and searching for Group resource. This enables clients to discover available groups based on stable characteristics such as Group.identifier. Note: How these groups are defined is implementation specific for each FHIR system. For example, a payer may send a healthcare institution a roster file that can be imported into their EHR to create or update a FHIR group. Group membership could be based upon explicit attributes of the patient, such as: age, sex or a particular condition such as PTSD or Chronic Opioid use, or on more complex attributes, such as a recent inpatient discharge or membership in the population used to calculate a quality measure. FHIR-based group management is out of scope for the current version of this implementation guide.",
  "code": "$export",
  "resource": ["Group"],
  "system": false,
  "type": false,
  "instance": true,
  "parameter": [
    {
      "name": "_outputFormat",
      "use": "out",
      "min": 0,
      "max": "1",
      "documentation": "The format for the requested bulk data files to be generated. Servers MUST support Newline Delimited JSON, but MAY choose to support additional output formats. Servers MUST accept the full content type of application/fhir+ndjson as well as the abbreviated representations application/ndjson and ndjson. Defaults to application/fhir+ndjson",
      "type": "string"
    },
    {
      "name": "_since",
      "use": "in",
      "min": 0,
      "max": "1",
      "documentation": "Resources updated after this period will be included in the response. ",
      "type": "instant"
    },
    {
      "name": "_type",
      "use": "out",
      "min": 0,
      "max": "1",
      "documentation": "A string of comma-delimited FHIR resource types. Only resources of the specified resource types(s) SHOULD be included in the response. If this parameter is omitted, the server SHOULD return all supported resources within the scope of the client authorization. For non-system-level requests, the Patient Compartment SHOULD be used as a point of reference for recommended resources to be returned as well as other resources outside of the patient compartment that are helpful in interpreting the patient data such as Organization and Practitioner. Resource references MAY be relative URIs with the format <resource type>/<id>, or absolute URIs with the same structure rooted in the base URI for the server from which the export was performed. References will be resolved looking for a resource with the specified type and id within the file set. Note: Implementations MAY limit the resources returned to specific subsets of FHIR, such as those defined in the Argonaut Implementation Guide",
      "type": "string"
    }
  ]
}
```