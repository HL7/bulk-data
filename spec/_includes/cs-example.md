```
{
  "resourceType": "CapabilityStatement",
...
  "rest": [{
   ...
      "security": {
        "service": [
          {
            "coding": [
              {
                "system": "http://hl7.org/fhir/restful-security-service",
                "code": "SMART-on-FHIR"
              }
            ],
            "text": "OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org)"
          }
        ],
        "extension": [
          {
            "url": "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris",
            "extension": [
              {
                "url": "token",
                "valueUri": "https://my-server.org/token"
              },
              {
                "url": "authorize",
                "valueUri": "https://my-server.org/authorize"
              },
              {
                "url": "manage",
                "valueUri": "https://my-server.org/authorizations/manage"
              }
              ,
              {
                "url": "introspect",
                "valueUri": "https://my-server.org/authorizations/introspect"
              },
              {
                "url": "revoke",
                "valueUri": "https://my-server.org/authorizations/revoke"
              }
            ]
          }
        ]      ...
```
