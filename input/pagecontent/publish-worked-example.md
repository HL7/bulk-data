### Bulk Publish Worked Example

This example shows one way to use `$bulk-publish` for a provider directory with complete snapshots, ordinary manifest paging, and stub-manifest incremental updates. The example is informative; the normative requirements are on the [Publish Operation](publish.html) page.

The JSON examples focus on the fields needed to explain the workflow. They do not show every HTTP header, such as `ETag`, and later examples may shorten repeated file lists when the surrounding text explains what has been omitted.

### Scenario

A health information exchange publishes a provider directory containing `Practitioner`, `PractitionerRole`, `Organization`, `Location`, and `Endpoint` resources.

The Data Provider publishes:

- a complete snapshot on the first day of each month;
- a weekly incremental update each Thursday;
- a new complete snapshot on April 1, 2026, when an upstream identifier migration requires Data Consumers on older chains to rebuild from a fresh snapshot.

### Timeline

| Date | Event | Manifest |
| --- | --- | --- |
| 2026-01-01 | Snapshot | `snapshot-2026-01` |
| 2026-01-01 | Stub manifest page | `update-chain-2026-01` |
| 2026-01-08 | Weekly update | `update-2026-01-08` |
| 2026-01-15 | Weekly update | `update-2026-01-15` |
| 2026-01-22 | Weekly update | `update-2026-01-22` |
| 2026-01-29 | Weekly update | `update-2026-01-29` |
| 2026-02-01 | Refreshed root snapshot | `snapshot-2026-02` |
| 2026-02-05 | Weekly update | `update-2026-02-05` |
| 2026-03-05 | Paged weekly update | `update-2026-03-05`, `update-2026-03-05-page-2` |
| 2026-04-01 | Snapshot and old-chain close | `snapshot-2026-04`, `#closed` |
| 2026-04-02 | Weekly update | `update-2026-04-02` |

Through March, all manifests in this example use the same chain. The February and March snapshots are newer starting points for new Data Consumers, but they do not require existing Data Consumers to restart. The April snapshot starts a new chain; older pages that still advertise `#pending` are closed so existing Data Consumers restart from the root endpoint.

### January Snapshot

On January 1, the root endpoint returns a complete snapshot. The root manifest includes a `next` link to a stub manifest page. The root manifest itself does not use `#pending` to allow for separate snapshot and incremental polling.

```
GET https://exchange.example.org/fhir/$bulk-publish
```

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-01-01T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "output": [{
    "type": "Practitioner",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-01-practitioner-1.ndjson"
  },{
    "type": "PractitionerRole",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-01-practitionerrole-1.ndjson"
  },{
    "type": "Organization",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-01-organization-1.ndjson"
  },{
    "type": "Location",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-01-location-1.ndjson"
  },{
    "type": "Endpoint",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-01-endpoint-1.ndjson"
  }],
  "link": [{
    "relation": "next",
    "url": "https://exchange.example.org/fhir/bulk/manifest/update-chain-2026-01"
  }]
}
```

After processing the snapshot files, the Data Consumer follows the `next` link.

### Stub Manifest Page

The stub manifest page has the same snapshot metadata as the root manifest, no files, and a `next` link URL of `#pending`.

```
GET https://exchange.example.org/fhir/bulk/manifest/update-chain-2026-01
```

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-01-01T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "link": [{
    "relation": "next",
    "url": "#pending"
  }]
}
```

The Data Consumer stores this manifest page URL and `ETag` header value and polls it using an `If-None-Match` header.

### First Weekly Update

On January 8, the Data Provider publishes `update-2026-01-08`. It then updates the stub manifest page so its `next` link points to the new manifest page.

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-01-01T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "link": [{
    "relation": "next",
    "url": "https://exchange.example.org/fhir/bulk/manifest/update-2026-01-08"
  }]
}
```

After polling at https://exchange.example.org/fhir/bulk/manifest/update-chain-2026-01 endpoint, the  Data Consumer follows the link to the January 8 incremental update.

```
GET https://exchange.example.org/fhir/bulk/manifest/update-2026-01-08
```

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-01-08T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "output": [{
    "type": "Practitioner",
    "url": "https://exchange.example.org/fhir/bulk/files/upd-01-08-practitioner-1.ndjson"
  },{
    "type": "PractitionerRole",
    "url": "https://exchange.example.org/fhir/bulk/files/upd-01-08-practitionerrole-1.ndjson"
  }],
  "deleted": [{
    "url": "https://exchange.example.org/fhir/bulk/files/upd-01-08-deleted-1.ndjson"
  }],
  "link": [{
    "relation": "next",
    "url": "#pending"
  }]
}
```

After processing this update, the Data Consumer polls `https://exchange.example.org/fhir/bulk/manifest/update-2026-01-08`. When the January 15 update is available, the Data Provider changes this page's `next` link from `#pending` to the URL of `update-2026-01-15`. This pattern repeats for the weekly chain.

### Refreshed Root Snapshot

On February 1, the Data Provider publishes a new complete snapshot at `[base]/$bulk-publish`. This is a fresher starting point for new Data Consumers, not a restart requirement for Data Consumers already following the January chain, because the existing chain remains open.

A new Data Consumer starting in February retrieves the February snapshot and follows its `next` link to a stub manifest page. Existing January Data Consumers continue polling the page at the end of their current chain. On February 5, the Data Provider can point both paths to the same `update-2026-02-05` manifest, allowing Data Consumers that started from different snapshots to converge.

### Paged Update

If a weekly update is large, the Data Provider can split one logical manifest across pages using ordinary `next` links. In this example, the March 5 update has two pages. Page 1 points to page 2 with an absolute URL, and page 2 is the page that the Data Consumer polls after processing both pages.

Page 1:

```
GET https://exchange.example.org/fhir/bulk/manifest/update-2026-03-05
```

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-03-05T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "output": [{
    "type": "Practitioner",
    "url": "https://exchange.example.org/fhir/bulk/files/upd-03-05-practitioner-1.ndjson"
  }],
  "link": [{
    "relation": "next",
    "url": "https://exchange.example.org/fhir/bulk/manifest/update-2026-03-05-page-2"
  }]
}
```

Page 2:

```
GET https://exchange.example.org/fhir/bulk/manifest/update-2026-03-05-page-2
```

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-03-05T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "output": [{
    "type": "PractitionerRole",
    "url": "https://exchange.example.org/fhir/bulk/files/upd-03-05-practitionerrole-1.ndjson"
  }],
  "link": [{
    "relation": "next",
    "url": "#pending"
  }]
}
```

The Data Consumer processes page 1 and then page 2 in manifest order. Because page 2 ends with `#pending`, the Data Consumer stores page 2's URL and polls it for the next update.

### Reconsolidation

On April 1, the Data Provider publishes a new complete snapshot at `[base]/$bulk-publish` and closes the older manifest chain. New Data Consumers simply start from this new root manifest.

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-04-01T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "output": [{
    "type": "Practitioner",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-04-practitioner-1.ndjson"
  },{
    "type": "PractitionerRole",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-04-practitionerrole-1.ndjson"
  },{
    "type": "Organization",
    "url": "https://exchange.example.org/fhir/bulk/files/snap-04-organization-1.ndjson"
  }],
  "link": [{
    "relation": "next",
    "url": "https://exchange.example.org/fhir/bulk/manifest/update-chain-2026-04"
  }]
}
```

Existing Data Consumers on the old chain learn about the reset when the Data Provider changes the current page's `next` link from `#pending` to `#closed`.

```json
{
  "manifestType": "http://hl7.org/fhir/uv/bulkdata/OperationDefinition/bulk-publish",
  "transactionTime": "2026-03-26T00:00:00Z",
  "requiresAccessToken": true,
  "updateCadence": "P7D",
  "output": [{
    "type": "Practitioner",
    "url": "https://exchange.example.org/fhir/bulk/files/upd-03-26-practitioner-1.ndjson"
  }],
  "link": [{
    "relation": "next",
    "url": "#closed"
  }]
}
```

When a Data Consumer sees `#closed`, it discards the old local dataset or marks it superseded according to local policy, retrieves the root manifest from `[base]/$bulk-publish`, and rebuilds from the new complete snapshot.
