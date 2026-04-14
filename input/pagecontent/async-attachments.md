##### Attachments

If resources in a returned file contain elements of the type `Attachment`, the {{ bulk_server_role }} SHOULD populate the `Attachment.contentType` code as well as either the `data` element or the `url` element. If the `data` element is not populated and the `url` element is populated, the `url` element SHALL be an absolute URL that can be dereferenced to the attachment's content.

When the `url` element is populated with an absolute URL and the `requiresAccessToken` field in the manifest is set to `true`, the URL location must be accessible by a {{ bulk_client_role }} with a valid access token and SHALL NOT require the use of additional authentication credentials. When the `url` element is populated and the `requiresAccessToken` field in the manifest is set to `false`, the URL location must be accessible by a {{ bulk_client_role }} without an access token.

Note that if a {{ bulk_server_role }} copies files to the Bulk Data output endpoint or proxies requests to facilitate access from this endpoint, it may need to modify the `Attachment.url` element when generating the Bulk Data output files.
