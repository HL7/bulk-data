---
title: SMART App Launch Framework
layout: default
---

The SMART App Launch Framework connects third-party applications to Electronic
Health Record data, allowing apps to launch from inside or outside the user
interface of an EHR system. The framework supports apps for use by clinicians,
patients, and others via a PHR or Patient Portal or any FHIR system where a user can give permissions to launch an app. It provides a reliable, secure authorization protocol for
a variety of app architectures, including apps that run on an end-user's device
as well as apps that run on a secure server.  The Launch Framework supports the
[four uses
cases](http://argonautwiki.hl7.org/images/4/4c/Argonaut_UseCasesV1.pdf) defined
for Phase 1 of the
[Argonaut Project](http://argonautwiki.hl7.org/index.php?title=Main_Page):

1. Patients apps that launch standalone
1. Patient apps that launch from a portal
1. Provider apps that launch standalone
1. Provider apps that launch from a portal

## Profile audience and scope

This profile is intended to be used by developers of apps that need to access
FHIR resources by requesting access tokens from OAuth 2.0 compliant
authorization servers. It is compatible with FHIR DSTU2 and above, and includes
explicit definitions for extensions in DSTU2 and STU3.

OAuth 2.0 authorization servers are configured to mediate access based on
a set of rules configured to enforce institutional policy, which may
include requesting end-user authorization.  This profile
does not dictate the institutional policies that are implemented in the
authorization server.

The profile defines a method through which an app requests
authorization to access a FHIR resource, and then uses that authorization
to retrieve the resource. Synchronization of patient context is not addressed.  In other words, if the patient chart is changed during the session, the application will not inherently be updated.  Other security mechanisms, such as those mandated by HIPAA in the US (end-user authentication, session time-out, security auditing,
and accounting of disclosures) are outside the scope of this profile.

## App protection

The app is responsible for protecting itself from potential misbehaving or
malicious values passed to its redirect URL (e.g., values injected with
executable code, such as SQL) and for protecting authorization codes, access
tokens, and refresh tokens from unauthorized access and use.  The app
developer must be aware of potential threats, such as malicious apps running
on the same platform, counterfeit authorization servers, and counterfeit
resource servers, and implement countermeasures to help protect both the app
itself and any sensitive information it may hold. For background, see the
[OAuth 2.0 Threat Model and Security
Considerations](https://tools.ietf.org/html/rfc6819).

* Apps SHALL ensure that sensitive information (authentication secrets,
authorization codes, tokens) is transmitted ONLY to authenticated servers,
over TLS-secured channels.

* Apps SHALL generate an unpredictable `state` parameter for each user
session.  An app SHALL validate the `state` value for any request sent to its
redirect URL; include `state` with all authorization requests; and validate
the `state` value included in access tokens it receives.

* An app SHALL NOT execute any inputs it receives as code.

* An app SHALL NOT forward values passed back to its redirect URL to any
other arbitrary or user-provided URL (a practice known as an “open
redirector”).

* An app SHALL NOT store bearer tokens in cookies that are transmitted
in the clear.

* Apps should persist tokens and other sensitive data in app-specific
storage locations only, not in system-wide-discoverable locations.

## Support for "public" and "confidential" apps

Within this profile we differentiate between the two types of apps defined in the [OAuth 2.0 specification: confidential and public](https://tools.ietf.org/html/rfc6749#section-2.1). The differentiation is based upon whether the execution environment within which the app runs
enables the app to protect secrets.   Pure client-side apps
(for example, HTML5/JS browser-based apps, iOS mobile
apps, or Windows desktop apps) can provide adequate security, but they may be unable to "keep a secret" in the OAuth2 sense.  In other words, any "secret" key, code, or
string that is statically embedded in the app can potentially be extracted by an end-user
or attacker. Hence security for these apps cannot depend on secrets embedded at
install-time.

For strategies and best practices to protecting a client secret refer to:

- OAuth 2.0 Threat Model and Security Considerations: [4.1.1. Threat: Obtaining Client Secrets](https://tools.ietf.org/html/rfc6819#section-4.1.1)
- OAuth 2.0 for Native Apps: [8.5. Client Authentication](https://tools.ietf.org/html/draft-ietf-oauth-native-apps-12#section-8.5)
- [OAuth 2.0 Dynamic Client Registration Protocol](https://tools.ietf.org/html/rfc7591)

#### Use the <span class="label label-primary">confidential app</span>  profile if your app is *able* to protect a `client_secret`

for example:

- App runs on a trusted server with only server-side access to the secret
- App is a native app that uses additional technology (such as dynamic client registration and universal redirect_uris) to protect the `client_secret`


#### Use the <span class="label label-primary">public app</span> profile if your app is *unable* to protect a `client_secret`

for example:

- App is an HTML5 or JS in-browser app that would expose the secret in user space
- App is a native app that can only distribute a `client_secret` statically

## Registering a SMART App with an EHR

Before a SMART app can run against an EHR, the app must be registered with that
EHR's authorization service.  SMART does not specify a standards-based registration process, but we
encourage EHR implementers to consider the [OAuth 2.0 Dynamic Client
Registration Protocol](https://tools.ietf.org/html/rfc7591)
for an out-of-the-box solution.

No matter how an app registers with an EHR's authorization service, at registration time **every SMART app must**:

* Register zero or more fixed, fully-specified launch URL with the EHR's authorization server
* Register one or more fixed, fully-specified `redirect_uri`s with the EHR's authorization server.  Note: In the case of native clients following the OAuth 2.0 for Native Apps specification [(RFC 8252)](https://tools.ietf.org/html/rfc8252), it may be appropriate to leave the port as a dynamic variable in an otherwise fixed redirect URI.

## SMART authorization & FHIR access: overview

An app can launch from within an existing EHR or Patient Portal session; this is known as an EHR launch.  Alternatively, it can launch as a standalone app.

In an <span class="label label-primary">EHR launch</span>, an opaque handle to
the EHR context is passed along to the app as part of the launch URL.  The app
later will include this context handle as a request parameter when it requests
authorization to access resources.  Note that the complete URLs of all apps
approved for use by users of this EHR will have been registered with the EHR
authorization server.

Alternatively, in a <span class="label label-primary">standalone launch</span>,
when the app launches from outside an EHR session, the app can request context
from the EHR authorization server during the authorization process described
below.

Once an app receives a launch request, it requests authorization to access a FHIR resource by
causing the browser to navigate to the EHR's authorization endpoint. Based
on pre-defined rules and possibly end-user authorization, the EHR authorization
server either grants the request by returning an authorization code to the app’s
redirect URL, or denies the request. The app then exchanges the authorization
code for an access token, which the app presents to the EHR’s resource server to
access requested FHIR resources. If a refresh token is returned along with the
access token, the app may use this to request a new access token, with the same
scope, once the access token expires.

## SMART "launch sequence"

The two alternative launch sequences are described below.

### EHR launch sequence

<div>
<img class="spec-image"  src="http://www.websequencediagrams.com/cgi-bin/cdraw?lz=RUhSIFNlc3Npb24gLT4-IEFwcDogUmVkaXJlY3QgdG8gaHR0cHM6Ly97YXBwIGxhdW5jaF91cml9P1xuAAgGPTEyMyZcbmlzcz0AIwlmaGlyIGJhc2UgdXJsfQpBcHAgLT4gRUhSIEZISVIgU2VydmVyOiBHRVQAVgoAJg4vbWV0YWRhdGEKACcPIC0AgR4HW0NvbmZvcm1hbmNlIHN0YXRlbWVudCBpbmNsdWRpbmcgT0F1dGggMi4wIGVuZHBvaW50IFVSTHNdAIEIBwCBCgZBdXRoegCBCAkAgWQVZWhyIGF1dGhvcml6AIFLBj9cbnNjb3BlPQCCCgYmXG4AewU9YWJjJgCCCA9hdWQ9AIIADyZcbi4uLgo&s=default"/>
</div>

In SMART's <span class="label label-primary">EHR launch</span> flow (shown above),
a user has established an EHR session, and then decides to launch an app. This
could be a single-patient app (which runs in the context of a patient record), or
a user-level app (like an appointment manager or a population dashboard). The EHR
initiates a "launch sequence" by opening a new browser instance (or `iframe`)
pointing to the app's registered launch URL and passing some context.

The following parameters are included:

<table class="table">
  <thead>
    <th colspan="3">Parameters</th>
  </thead>
  <tbody>
    <tr>
      <td><code>iss</code></td>
      <td><span class="label label-success">required</span></td>
      <td>

Identifies the EHR's FHIR endpoint, which the app can use to obtain
additional details about the EHR, including its authorization URL.

      </td>
    </tr>
    <tr>
      <td><code>launch</code></td>
      <td><span class="label label-success">required</span></td>
      <td>

      Opaque identifier for this specific launch, and any EHR context associated
with it. This parameter must be communicated back to the EHR  at authorization
time by passing along a <code>launch</code> parameter (see example below).

      </td>
    </tr>
  </tbody>
</table>


#### *For example*
A launch might cause the browser to navigate to:

    Location: https://app/launch?iss=https%3A%2F%2Fehr%2Ffhir&launch=xyz123

On receiving the launch notification, the app would query the issuer's `/metadata/` endpoint or
[.well-known/smart-configuration.json] endpoint which contains (among other details) the EHR's identifying the OAuth `authorize` and `token`
endpoint URLs for use in requesting authorization to access FHIR
resources.

Later, when the app prepares a list of access scopes to request from
the EHR authorization server, it will be associated with the existing EHR context by
including the launch notification in the scope.

### Standalone launch sequence

<div>
<img class="spec-image"  src="http://www.websequencediagrams.com/cgi-bin/cdraw?lz=QXBwIC0-IEVIUiBGSElSIFNlcnZlcjogR0VUIGh0dHBzOi8ve2ZoaXIgYmFzZSB1cmx9L21ldGFkYXRhCgAnDyAtPiBBcHA6IFtDb25mb3JtYW5jZSBzdGF0ZW1lbnQgaW5jbHVkaW5nIE9BdXRoIDIuMCBlbmRwb2ludCBVUkxzXQoAgQkGAIEKBkF1dGh6AIEICVJlZGlyZWN0IHRvAIEPCmVociBhdXRob3JpegCBFwY_XG5zY29wZT1sYXVuY2gmXG4AewU9YWJjJlxuYXVkPQCBPw8mXG4uLi4KCg&s=default"/>
</div>

Alternatively, in SMART's <span class="label label-primary">standalone
launch</span> flow (shown above), a user selects an app from outside the EHR,
for example by tapping an app icon on a mobile phone home screen. This app
will launch from its registered URL without a launch id.   

In order to obtain launch context and request authorization to access FHIR
resources, the app discovers the EHR authorization server's OAuth
`authorize` and `token` endpoint URLs by querying their
[.well-known/smart-configuration.json] file.

The app then can declare its launch context requirements
by adding specific scopes to the request it sends to the EHR's authorization
server.  The `authorize` endpoint
will acquire the context the app needs and make it available.

#### *For example:*

If the app needs patient context, the EHR's authorization server
may provide the end-user with a
patient selection widget.  For full details, see <a href="scopes-and-launch-context/index.html">SMART launch context parameters</a>.

*	launch/patient - to indicate that the app needs to know a patient ID
*	launch/encounter - to indicate the app needs an encounter


## SMART authorization and resource retrieval

### *SMART authorization sequence*

<div>
<img class="spec-image" src="http://www.websequencediagrams.com/cgi-bin/cdraw?lz=bm90ZSBsZWZ0IG9mIEFwcDogUmVxdWVzdCBhdXRob3JpemF0aW9uCkFwcCAtPj4gRUhSIEF1dGh6IFNlcnZlcjogUmVkaXJlY3QgaHR0cHM6Ly97ZWhyADUJZV91cmx9Py4uLgoAZgVvdmVyADITQQAnCCBBcHBcbihtYXkgaW5jbHVkZSBlbmQtdXNlAE4GZW50aWMAgQ4FXG5hbmQADw4AgSYJKQpOb3RlIABWGE9uIGFwcHJvdmFsCgCBQRAgLT4-AIIBBwCBSBBhcHAgcgCBZwdfdXJpfT9jb2RlPTEyMyYAgVcJAII-DUV4Y2hhbmdlIGNvZGUgZm9yIGFjY2VzcyB0b2tlbjtcbmlmIGNvbmZpZGVudGlhbCBjbGllbnQsAIFyCXNlY3JldApBcHAtPgCCaBJQT1NUAIJsCgBPBSB1cmx9XG5ncmFudF90eXBlPQCDOg1fY29kZSYAgSQSAIJ7GwCCagdlIGEAgxQFAIEcFgCCaQcAg0YXSXNzdWUgbmV3AIFyBiB3aXRoIGNvbnRleHQ6XG4ge1xuIgCCEwZfAIIUBSI6IgCBcwYtAIIjBS14eXoiLFxuImV4cGlyZXMtaW4iOjM2MDAsXG4icGF0aWVudCI6IjQ1NiIsXG4uLi5cbn0Ag0MUAIVZBVsAgnYMIHJlc3BvbnNlXQ&s=default&h=NA3OIkJNCqFraI5a">
</div>

<a id="step-1"></a>

#### Step 1: App asks for authorization

At launch time, the app constructs a request for authorization by adding the
following parameters to the query component of the EHR’s "authorize" endpoint
URL.:

<table class="table">
  <thead>
    <th colspan="3">Parameters</th>
  </thead>
  <tbody>
    <tr>
      <td><code>response_type</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Fixed value: <code>code</code>. </td>
    </tr>
    <tr>
      <td><code>client_id</code></td>
      <td><span class="label label-success">required</span></td>
      <td>The client's identifier. </td>
    </tr>
    <tr>
      <td><code>redirect_uri</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Must match one of the client's pre-registered redirect URIs.</td>
    </tr>
    <tr>
      <td><code>launch</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>When using the <span class="label label-primary">EHR launch</span>flow, this must match the launch value received from the EHR.</td>
    </tr>
    <tr>
      <td><code>scope</code></td>
      <td><span class="label label-success">required</span></td>
      <td>

Must describe the access that the app needs, including clinical data scopes like
<code>patient/*.read</code>, <code>openid</code> and <code>fhirUser</code> (if app
needs authenticated patient identity) and either:

<ul>
<li> a <code>launch</code> value indicating that the app wants to receive already-established launch context details from the EHR </li>
<li> a set of launch context requirements in the form <code>launch/patient</code>, which asks the EHR to establish context on your behalf.</li>
</ul>

See <a href="scopes-and-launch-context/index.html">SMART on FHIR Access
Scopes</a> details.

      </td>
    </tr>
    <tr>
      <td><code>state</code></td>
      <td><span class="label label-success">required</span></td>
      <td>

An opaque value used by the client to maintain state between the request and
callback. The authorization server includes this value when redirecting the
user-agent back to the client. The parameter SHALL be used for preventing
cross-site request forgery or session fixation attacks.

      </td>
    </tr>
     <tr>
      <td><code>aud</code></td>
      <td><span class="label label-success">required</span></td>
      <td>

URL of the EHR resource server from which the app wishes to retrieve FHIR data.
This parameter prevents leaking a genuine bearer token to a counterfeit
resource server. (Note: in the case of an <span class="label label-primary">EHR launch</span>
flow, this <code>aud</code> value is the same as the launch's <code>iss</code> value.)

      </td>
    </tr>
  </tbody>
</table>

The app SHALL use an unpredictable value for the state parameter
with at least 122 bits of entropy (e.g., a properly configured random uuid is suitable). The app SHALL validate the value
of the state parameter upon return to the redirect URL and SHALL ensure
that the state value is securely tied to the user’s current session
(e.g., by relating the state value to a session identifier issued
by the app). The app SHOULD limit the grants, scope, and period of
time requested to the minimum necessary.

If the app needs to authenticate the identity of the end-user, it should
include two OpenID Connect scopes:  `openid` and `fhirUser`.   When these scopes
are requested, and the request is granted, the app will receive an id_token
along with the access token.  For full details, see [SMART launch context
parameters](scopes-and-launch-context/index.html).

##### *For example*
If an app needs demographics and observations for a single
patient, and also wants information about the current logged-in user, the app  can request:

* `patient/Patient.read`
* `patient/Observation.read`
* `openid fhirUser`

If the app was launched from an EHR, the app adds a `launch` scope and a
`launch={launch id}` URL parameter, echoing the value it received from the EHR
to be associated with the EHR context of this launch notification.

*Apps using the <span class="label label-primary">standalone launch</span> flow
won't have a `launch` id at this point.  These apps can declare launch context
requirements by adding specific scopes to the authorization request: for
example, `launch/patient` to indicate that the app needs a patient ID, or
`launch/encounter` to indicate it needs an encounter.  The EHR's "authorize"
endpoint will take care of acquiring the context it needs (making it available to the app).  
For example, if your app needs patient context, the EHR may
provide the end-user with a patient selection widget.  For full details, see <a
href="scopes-and-launch-context/index.html">SMART launch
context parameters</a>.*


The app then causes the browser to navigate the browser to the EHR's **authorization URL** as
determined above. For example:


```
Location: https://ehr/authorize?
            response_type=code&
            client_id=app-client-id&
            redirect_uri=https%3A%2F%2Fapp%2Fafter-auth&
            launch=xyz123&
            scope=launch+patient%2FObservation.read+patient%2FPatient.read+openid+fhirUser&
            state=98wrghuwuogerg97&
            aud=https://ehr/fhir
```

<a id="step-2"></a>

#### Step-2: EHR evaluates authorization request, asking for end-user input

The authorization decision is up to the EHR authorization server,
which may request authorization from the end-user. The EHR authorization
server will enforce access rules based on local policies and optionally direct
end-user input.

The EHR decides whether to grant or deny access.  This decision is
communicated to the app when the EHR authorization server returns an
authorization code (or, if denying access, an error response).  Authorization codes are short-lived, usually expiring
within around one minute.  The code is sent when the EHR authorization server
causes the browser to navigate to the app's <code>redirect_uri</code>, with the
following URL parameters:

<table class="table">
  <thead>
    <th colspan="3">Parameters</th>
  </thead>
  <tbody>
    <tr>
      <td><code>code</code></td>
      <td><span class="label label-success">required</span></td>

      <td>

The authorization code generated by the authorization server. The
authorization code *must* expire shortly after it is issued to mitigate the
risk of leaks.

      </td>
    </tr>
    <tr>
      <td><code>state</code></td>
      <td><span class="label label-success">required</span></td>
      <td>The exact value received from the client.</td>
    </tr>
  </tbody>
</table>

##### *For example*

Based on the `client_id`, current EHR user, configured policy, and perhaps
direct user input, the EHR makes a decision to approve or deny access.  This
decision is communicated to the app by causing the browser to navigate to the app's registered
`redirect_uri`. For example:

```
Location: https://app/after-auth?
  code=123abc&
  state=98wrghuwuogerg97
```



<a id="step-3"></a>

#### Step-3: App exchanges authorization code for access token

After obtaining an authorization code, the app trades the code for an access
token via HTTP `POST` to the EHR authorization server's token endpoint URL,
using content-type `application/x-www-form-urlencoded`, as described in
[section 4.1.3 of RFC6749](https://tools.ietf.org/html/rfc6749#section-4.1.3).

For <span class="label label-primary">public apps</span>, authentication is not
possible (and thus not required), since a client with no secret cannot prove its
identity when it issues a call. (The end-to-end system can still be secure
because the client comes from a known, https protected endpoint specified and
enforced by the redirect uri.)  For <span class="label
label-primary">confidential apps</span>, an `Authorization` header using HTTP
Basic authentication is required, where the username is the app's `client_id`
and the password is the app's `client_secret` (see
[example](basic-auth-example/index.html)).


<table class="table">
  <thead>
    <th colspan="3">Parameters</th>
  </thead>
  <tbody>
    <tr>
      <td><code>grant_type</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Fixed value: <code>authorization_code</code></td>
    </tr>
    <tr>
      <td><code>code</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Code that the app received from the authorization server</td>
    </tr>
    <tr>
      <td><code>redirect_uri</code></td>
      <td><span class="label label-success">required</span></td>
      <td>The same redirect_uri used in the initial authorization request</td>
    </tr>
    <tr>
      <td><code>client_id</code></td>
      <td><span class="label label-warning">conditional</span></td>
      <td>Required for <span class="label label-primary">public apps</span>. Omit for <span class="label label-primary">confidential apps</span>.</td>
    </tr>
  </tbody>
</table>

The EHR authorization server SHALL return a JSON object that includes an access token
or a message indicating that the authorization request has been denied. The JSON structure
includes the following parameters:

<table class="table">
  <thead>
    <th colspan="3">Parameters</th>
  </thead>
  <tbody>
    <tr>
      <td><code>access_token</code></td>
      <td><span class="label label-success">required</span></td>
      <td>The access token issued by the authorization server</td>
    </tr>
    <tr>
      <td><code>token_type</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Fixed value: <code>Bearer</code></td>
    </tr>
    <tr>
      <td><code>expires_in</code></td>
      <td><span class="label label-info">recommended</span></td>
      <td>Lifetime in seconds of the access token, after which the token SHALL NOT be accepted by the resource server</td>
    </tr>
    <tr>
      <td><code>scope</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Scope of access authorized. Note that this can be different from the scopes requested by the app.</td>
    </tr>
    <tr>
      <td><code>id_token</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>Authenticated patient identity and user details, if requested</td>
    </tr>
      <tr>
      <td><code>refresh_token</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>Token that can be used to obtain a new access token, using the same or a subset of the original authorization grants</td>
    </tr>
  </tbody>
</table>

In addition, if the app was launched from within a patient context,
parameters to communicate the context values MAY BE included. For example,
a parameter like `"patient": "123"` would indicate the FHIR resource
https://[fhir-base]/Patient/123. Other context parameters may also
be available. For full details see [SMART launch context parameters](scopes-and-launch-context/index.html).

The parameters are included in the entity-body of the HTTP response, as
described in section 5.1 of [RFC6749](https://tools.ietf.org/html/rfc6749).

The access token is a string of characters as defined in
[RFC6749](https://tools.ietf.org/html/rfc6749) and
[RFC6750](http://tools.ietf.org/html/rfc6750).  The token is essentially
a private message that the authorization server
passes to the FHIR Resource Server, telling the FHIR server that the
"message bearer" has been authorized to access the specified resources.  
Defining the format and content of the access token is left up to the
organization that issues the access token and holds the requested resource.

The authorization server's response SHALL
include the HTTP "Cache-Control" response header field with a value
of "no-store," as well as the "Pragma" response header field with a
value of "no-cache."

The EHR authorization server decides what `expires_in` value to assign to an
access token and whether to issue a refresh token, as defined in section 1.5
of [RFC6749](https://tools.ietf.org/html/rfc6749#page-10), along with the
access token.  If the app receives a refresh token along with the access
token, it can exchange this refresh token for a new access token when the
current access token expires (see step 5 below).  A refresh token SHALL
BE bound to the same `client_id` and SHALL contain the same, or a subset of,
the set of claims authorized for the access token with which it is associated.  

Apps SHOULD store tokens in app-specific storage locations only, not in
system-wide-discoverable locations.  Access tokens SHOULD have a valid
lifetime no greater than one hour.  Confidential
clients may be issued longer-lived tokens than public clients.

*A large range of threats to access tokens can be mitigated by digitally
signing the token as specified in [RFC7515](https://tools.ietf.org/html/rfc7515)
or by using a Message Authentication Code (MAC) instead.  Alternatively,
an access token can contain a reference to authorization information,
rather than encoding the information directly into the token itself.  
To be effective, such references must be infeasible for an attacker to
guess.  Using a reference may require an extra interaction between the
resource server and the authorization server; the mechanics of such an
interaction are not defined by this specification.*


##### *For example*

Given an authorization code, the app trades it for an access token via HTTP
`POST`.

###### Request for

```
POST /token HTTP/1.1
Host: ehr
Authorization: Basic bXktYXBwOm15LWFwcC1zZWNyZXQtMTIz
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=123abc&
redirect_uri=https%3A%2F%2Fapp%2Fafter-auth
```

###### Response

```
{
  "access_token": "i8hweunweunweofiwweoijewiwe",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "patient/Observation.read patient/Patient.read",
  "intent": "client-ui-name",
  "patient":  "123",
  "encounter": "456"
}
```

[See full payload example](example-request-token-post/index.html).

At this point, **the authorization flow is complete**. Follow steps below to work with
data and refresh access tokens, as shown in the following sequence diagram.

#### *SMART retrieval and refresh sequence*
<div>
<img class="spec-image"
src="http://www.websequencediagrams.com/cgi-bin/cdraw?lz=bm90ZSBvdmVyIEFwcDogQWNjZXNzIHBhdGllbnQgZGF0YSAKQXBwLT5FSFIgRkhJUiBTZXJ2ZXI6IEdFVCBodHRwczovL3tmaGlyIGJhc2UgdXJsfS9QADoGLzEyMwoAWAoAMhFSZXR1cm4AUQZyZXNvdXJjZSB0byBhcHAKAGEPLT4AgRsFeyIAIAhUeXBlIjogIgBkByIsICJiaXJ0aERhdGUiOi4uLn0AbwsAgVAMdG9rZW4gZXhwaXJlcy4uLgAXEC4uLiBzbyByZXF1ZXN0IGEgbmV3AC8GAIF_CkF1dGh6AIIBCSBQT1MAggELAFsGdXJsfVxuZ3JhbnRfdHlwZT1yZWZyZXNoXwB7BSZcbgADDT1hYmMAghsSAFkOQXV0aGVudGljYXRlIGFwcFxuKGlmIGNvbmZpZGVudGlhbCBjbGllbnQpCk4ALBtJc3N1ZQCBSwpcbntcbiJhAINzBQCBFgYiOiAic2VjcmV0LQCCJwUteHl6IixcbiIAgi0HX2luIjogMzYwMCxcbiIAgUoNIjogIm5leHQtAIFmBy0xMjMiXG4uLi5cbn0KfQoAg1EFAIIxDACDUAdbAHoGAIMVB3Jlc3BvbnNlXQoKCgoKCgABBQo&s=">
</div>


<a id="step-4"></a>

#### Step 4: App accesses clinical data via FHIR API

With a valid access token, the app can access protected EHR data by issuing a
FHIR API call to the FHIR endpoint on the EHR's resource server. The request includes an
`Authorization` header that presents the `access_token` as a "Bearer" token:

{% raw %}
    Authorization: Bearer {{access_token}}
{% endraw %}

(Note that in a real request, `{% raw %}{{access_token}}{% endraw %}`{:.language-text} is replaced
with the actual token value.)

##### *For example*
With this response, the app knows which patient is in-context, and has an
OAuth2 bearer-type access token that can be used to fetch clinical data:

###### Request
``` text
GET https://ehr/fhir/Patient/123
Authorization: Bearer i8hweunweunweofiwweoijewiwe
```

###### Response
```
{
  "resourceType": "Patient",
  "birthTime": ...
}
```

[See full payload example](example-request-patient/index.html).

The resource server SHALL validate the access token and ensure that it has not expired and that its scope covers the requested resource.  The
resource server also validates that the `aud` parameter associated with the
authorization (see <a href="#step-1">above</a>) matches the resource server's own FHIR
endpoint.  The method used by the EHR to validate the access token is beyond
the scope of this specification but generally involves an interaction or
coordination between the EHR’s resource server and the authorization server.

On occasion, an app may receive a FHIR resource that contains a “reference” to
a resource hosted on a different resource server.  The app SHOULD NOT blindly
follow such references and send along its access_token, as the token may be
subject to potential theft.   The app SHOULD either ignore the reference, or
initiate a new request for access to that resource.


<a id="step-5"></a>

#### Step 5: (Later...) App uses a refresh token to obtain a new access token

Refresh tokens are issued to enable sessions to last longer than the validity period of an access token.  The app can use the `expires_in` field from the token response (see <a href="#step-3">step 3</a>) to determine when its access token will expire.  EHR implementers are also encouraged to consider using the [OAuth 2.0 Token Introspection Protocol](https://tools.ietf.org/html/rfc7662) to provide an introspection endpoint that clients can use to examine the validity and meaning of tokens. An app with "online access" can continue to get new access tokens as long as the end-user remains online.  Apps with "offline access" can continue to get new access tokens without the user being interactively engaged for cases where an application should have long-term access extending beyond the time when a user is still interacting with the client.

The app requests a refresh token in its authorization request via the `online_access` or `offline_access` scope (see <a href="scopes-and-launch-context/index.html">SMART on FHIR Access Scopes</a> for details).  A server can decide which client types (public or confidential) are eligible for offline access and able to receive a refresh token.  If granted, the EHR supplies a refresh_token in the token response.  After an access token expires, the app requests a new access token by providing its refresh token to the EHR's token endpoint.  An HTTP `POST` transaction is made to the EHR authorization server's token URL, with content-type `application/x-www-form-urlencoded`. The decision about how long the refresh token lasts is determined by a mechanism that the server chooses.  For clients with online access, the goal is to ensure that the user is still online.

- For <span class="label label-primary">public apps</span>, authentication is not possible (and thus not required). For <span class="label label-primary">confidential apps</span>, an `Authorization` header using HTTP

The following request parameters are defined:

<table class="table">
  <thead>
    <th colspan="3">Parameters</th>
  </thead>
  <tbody>

    <tr>
      <td><code>grant_type</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Fixed value: <code>refresh_token</code>. </td>
    </tr>
    <tr>
      <td><code>refresh_token</code></td>
      <td><span class="label label-success">required</span></td>
      <td>The refresh token from a prior authorization response</td>
    </tr>
    <tr>
      <td><code>scope</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>
The scopes of access requested. If present, this value must be a strict sub-set
of the scopes granted in the original launch (no new permissions can be
obtained at refresh time). A missing value indicates a request for the same
scopes granted in the original launch.
      </td>
    </tr>
  </tbody>
</table>
The response is a JSON object containing a new access token, with the following claims:

<table class="table">
  <thead>
    <th colspan="3">JSON Object property name</th>
  </thead>
  <tbody>
    <tr>
      <td><code>access_token</code></td>
      <td><span class="label label-success">required</span></td>
      <td>New access token issued by the authorization server.</td>
    </tr>
    <tr>
      <td><code>token_type</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Fixed value: bearer</td>
    </tr>
    <tr>
      <td><code>expires_in</code></td>
      <td><span class="label label-success">required</span></td>
      <td>The lifetime in seconds of the access token. For example, the value 3600 denotes that the access token will expire in one hour from the time the response was generated.</td>
    </tr>
    <tr>
      <td><code>scope</code></td>
      <td><span class="label label-success">required</span></td>
      <td>Scope of access authorized. Note that this will be the same as the scope of the original access token, and it can be different from the scopes requested by the app.</td>
    </tr>
    <tr>
      <td><code>refresh_token</code></td>
      <td><span class="label label-info">optional</span></td>
      <td>The refresh token issued by the authorization server. If present, the app should discard any previosu <code>refresh_token</code> associated with this launch, replacing it with this new value.</td>
    </tr>
  </tbody>
</table>

In addition, if the app was launched from within a patient context,
parameters to communicate the context values MAY BE included. For example,
a parameter like `"patient": "123"` would indicate the FHIR resource
https://[fhir-base]/Patient/123. Other context parameters may also
be available. For full details see [SMART launch context parameters](scopes-and-launch-context/index.html).

##### *For example*
If the EHR supports refresh tokens, an app may be able to replace an expired
access token programatically, without user interaction:

###### Request

```
POST /token HTTP/1.1
Host: ehr
Authorization: Basic bXktYXBwOm15LWFwcC1zZWNyZXQtMTIz
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&
refresh_token=a47txjiipgxkvohibvsm
```

###### Response

```
{
  "access_token": "m7rt6i7s9nuxkjvi8vsx",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "patient/Observation.read patient/Patient.read",
  "refresh_token":"tGzv3JOkF0XG5Qx2TlKWIA"
}
```

[See full payload example](example-request-refresh/index.html).

[.well-known/smart-configuration.json]: conformance/index.html#using-well-known
