---
title: "SMART App Launch: Conformance"
layout: default
---

The SMART's App Launch specification enables apps to launch and securely interact with EHRs.
The specification can be described as a set of capabilities and a given SMART on FHIR server implementation
may implement a subset of these.  The methods of declaring a server's SMART authorization endpoints and launch capabilities are described in the sections below.

## SMART on FHIR OAuth authorization Endpoints

The server SHALL convey the FHIR OAuth authorization endpoints that are listed in the table below to app developers.  The server SHALL use *both*:

1. A [FHIR CapabilityStatement](#using-cs)
1. A [Well-Known Uniform Resource Identifiers (URIs)](#using-well-known) JSON file.

to declare its SMART authorization endpoints. (Note that we require both because the specification is transitioning away from CapabilityStatement, but needs to preserve compatibility with existing implementations.)

*Note* that while this specification does not require that absolute URIs be used for OAuth authorization endpoints, absolute URIs are a recommended practice and may be required in a future release.

## SMART on FHIR Core Capabilities and Capability Sets

The server SHALL convey the *optional* SMART Core Capabilities it supports using:

- A [Well-Known Uniform Resource Identifiers (URIs)](#using-well-known) JSON file.

### Core Capabilities

To promote interoperability, the following SMART on FHIR *Core Capabilities* have been defined:

#### Launch Modes

* `launch-ehr`: support for SMART's EHR Launch mode  
* `launch-standalone`: support for SMART's Standalone Launch mode  

#### Client Types

* `client-public`: support for SMART's public client profile (no client authentication)  
* `client-confidential-symmetric`: support for SMART's confidential client profile (symmetric client secret authentication)

#### Single Sign-on

* `sso-openid-connect`: support for SMART's OpenID Connect profile

#### Launch Context

The following capabilities convey that a SMART on FHIR server is capable of providing basic context
to an app at launch time. These capabilities apply during an EHR Launch or a Standalone Launch:

* `context-banner`: support for "need patient banner" launch context (conveyed via `need_patient_banner` token parameter)
* `context-style`: support for "SMART style URL" launch context (conveyed via `smart_style_url` token parameter)

##### Launch Context for EHR Launch

When a SMART on FHIR server supports the launch of an app from _within_ an
existing user session ("EHR Launch"), the server has an opportunity to pass
existing, already-established context (such as the current patient ID) through
to the launching app. Using the following capabilities, a server declares its
ability to pass context through to an app at launch time:

* `context-ehr-patient`: support for patient-level launch context (requested by `launch/patient` scope, conveyed via `patient` token parameter)
* `context-ehr-encounter`: support for encounter-level launch context (requested by `launch/encounter` scope, conveyed via `encounter` token parameter)

##### Launch Context for Standalone Launch

When a SMART on FHIR server supports the launch of an app from _outside_ an
existing user session ("Standalone Launch"), the server may be able to
proactively resolve new context to help establish the details required for an
app launch. For example, an external app may request that the SMART on FHIR
server should work with the end-user to establish a patient context before
completing the launch.

* `context-standalone-patient`: support for patient-level launch context (requested by `launch/patient` scope, conveyed via `patient` token parameter)
* `context-standalone-encounter`: support for encounter-level launch context (requested by `launch/encounter` scope, conveyed via `encounter` token parameter)

#### Permissions

* `permission-offline`: support for refresh tokens (requested by `offline_access` scope)
* `permission-patient`: support for patient-level scopes (e.g. `patient/Observation.read`)
* `permission-user`: support for user-level scopes (e.g. `user/Appointment.read`)

<br />

[well-known]: ../well-known/index.html


### Capability Sets

Additionally, Four *Capability Sets* are defined.  Any individual SMART server will publish a granular list of its capabilities; from this list a client can determine which of these Capability Sets are supported:

#### Patient Access for Standalone Apps
1. `launch-standalone`
1. At least one of `client-public` or `client-confidential-symmetric`
1. `context-standalone-patient`
1. `permission-patient`

####  Patient Access for EHR Launch (i.e. from Portal)
1. `launch-ehr`
1. At least one of `client-public` or `client-confidential-symmetric`
1. `context-ehr-patient`
1. `permission-patient`

####  Clinician Access for Standalone
1. `launch-standalone`
1. At least one of `client-public` or `client-confidential-symmetric`
1. `permission-user`
1. `permission-patient`

####  Clinician Access for EHR Launch
1. `launch-ehr`
1. At least one of `client-public` or `client-confidential-symmetric`
1. `context-ehr-patient` support
1. `context-ehr-encounter` support
1. `permission-user`
1. `permission-patient`

## FHIR Authorization Endpoint and Capabilities Discovery using a FHIR CapabilityStatement
{:. #using-cs}

### Declaring Support for OAuth2 Endpoints

If a server supports SMART on FHIR authorization for access, it declares support for
automated discovery of OAuth2 endpoints in its [CapabilityStatement]({{site.data.fhir.path}}capabilitystatement.html) using the [OAuth Uri extension](#oauth-uris-extension) on the `rest.security` element (or, when using FHIR DSTU2, the
`Conformance.rest.security` element). Any time a client sees this extension, it
must be prepared to authorize using SMART's OAuth2-based protocol.

The OAuth extension has the following internal components:

|Component|Conformance Expectation|Type|Description|
|---|---|---|---|
|authorize|**SHALL**|`valueUri`|URL to the OAuth2 authorization endpoint.|
|token|**SHALL**|`valueUri`|URL to the OAuth2 token endpoint.|
|register|**SHOULD**|`valueUri`|If available, URL to the OAuth2 dynamic registration endpoint for this FHIR server.|
|manage|**SHOULD**|`valueUri`|If available, URL where an end-user can view which applications currently have access to data and can make adjustments to these access rights.|
|introspect|**SHOULD**|`valueUri`|URL to a server’s introspection endpoint that can be used to validate a token.|
|revoke|**SHOULD**|`valueUri`|URL to a server’s endpoint that can be used to revoke a token.|
{:.grid}


<!-- =======  reference to formal definition ============== -->

#### OAuth URIs Extension

- [**STU3 StructureDefinition for OAuth-URI**](../StructureDefinition-oauth-uris.html)
- [**DSTU2  StructureDefinition for OAuth-URI**](../StructureDefinition-dstu2-oauth-uris.html)


<!-- {% raw %}
{ % include StructureDefinition-oauth-uris-inline.html % }
 {% endraw %} -->

<!-- =======   reference to formal definition ============== -->


<!--
### Publishing Additional Conformance Details

A SMART on FHIR server should also describe which *optional* SMART core set of capabilities is it supports by declaring it within the CapabilityStatement [capabilities extension](#capabilities-extension) on the `rest.security` element (or, when using FHIR DSTU2, the
`Conformance.rest.security` element).


=======  inline view of extension ==============

#### SMART Capabilities Extension

Full StructureDefinition: [STU3](/StructureDefinition-extension-smart-capabilities.html), [DSTU2](/todo.html)

{%raw%}{% include StructureDefinition-extension-smart-capabilities-inline.html %}{%endraw%}

 =======    end inline view of extension ==============

-->

### Example

{% include cs-example.md %}

( for a complete example see the [CapabilityStatement Example](../CapabilityStatement-smart-app-launch-example.html) )

## FHIR Authorization Endpoint and Capabilities Discovery using a Well-Known Uniform Resource Identifiers (URIs)
{: #using-well-known}

As an alternative to using a FHIR CapabilityStatement, the authorization endpoints accepted by a FHIR resource server can be exposed as a Well-Known Uniform Resource Identifiers (URIs) [(RFC5785)][well-known] JSON document.

FHIR endpoints requiring authorization SHALL serve a JSON document at the location formed by appending `/.well-known/smart-configuration` to their base URL.
Contrary to RFC5785 Appendix B.4, the `.well-known` path component may be appended even if the FHIR endpoint already contains a path component.

### Request

Sample requests:

#### Base URL "fhir.ehr.example.com"

```
GET /.well-known/smart-configuration HTTP/1.1
Host: fhir.ehr.example.com
```

#### Base URL "www.ehr.example.com/apis/fhir"

```
GET /apis/fhir/.well-known/smart-configuration HTTP/1.1
Host: www.ehr.example.com
```

### Response

A JSON document must be returned using the `application/json` mime type.

#### Metadata

- `authorization_endpoint`: **REQUIRED**, URL to the OAuth2 authorization endpoint.
- `token_endpoint`: **REQUIRED**, URL to the OAuth2 token endpoint.
- `token_endpoint_auth_methods`: **OPTIONAL**, array of client authentication methods supported by the token endpoint. The options are "client_secret_post" and "client_secret_basic".
- `registration_endpoint`: **OPTIONAL**, if available, URL to the OAuth2 dynamic registration endpoint for this FHIR server.
- `scopes_supported`: **RECOMMENDED**, array of scopes a client may request. See [scopes and launch context][smart-scopes].
- `response_types_supported`: **RECOMMENDED**, array of OAuth2 `response_type` values that are supported
- `management_endpoint`: **RECOMMENDED**, URL where an end-user can view which applications currently have access to data and can make adjustments to these access rights.
- `introspection_endpoint` :  **RECOMMENDED**, URL to a server's introspection endpoint that can be used to validate a token.
- `revocation_endpoint` :  **RECOMMENDED**, URL to a server's revoke endpoint that can be used to revoke a token.
- `capabilities`: **REQUIRED**, array of strings representing SMART capabilities (e.g., `single-sign-on` or `launch-standalone`) that the server supports.


### Sample Response

```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "authorization_endpoint": "https://ehr.example.com/auth/authorize",
  "token_endpoint": "https://ehr.example.com/auth/token",
  "token_endpoint_auth_methods_supported": ["client_secret_basic"],
  "registration_endpoint": "https://ehr.example.com/auth/register",
  "scopes_supported": ["openid", "profile", "launch", "launch/patient", "patient/*.*", "user/*.*", "offline_access"],
  "response_types_supported": ["code", "code id_token", "id_token", "refresh_token"],
  "management_endpoint": "https://ehr.example.com/user/manage"
  "introspection_endpoint": "https://ehr.example.com/user/introspect"
  "revocation_endpoint": "https://ehr.example.com/user/revoke",
  "capabilities": ["launch-ehr", "client-public", "client-confidential-symmetric", "context-ehr-patient", "sso-openid-connect"]
}
```

### Well-Known URI Registry

- URI Suffix: smart-configuration

[well-known]: https://tools.ietf.org/html/rfc5785
[oid]: https://openid.net/specs/openid-connect-discovery-1_0.html
[smart-scopes]: http://docs.smarthealthit.org/authorization/scopes-and-launch-context/#quick-start
[extensions]:{{site.data.fhir.path}}extensibility.html
