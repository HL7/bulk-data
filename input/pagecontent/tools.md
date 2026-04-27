# Tools

This page describes optional reviewer tooling for annotating generated IG pages.
These tools are not part of the published specification.

## LLM DOM Annotator

The LLM DOM Annotator is maintained in this repository at
`input/images/llm-dom-annotator.js`. The IG Publisher copies this file to the
published output so it can be loaded as a bookmarklet when reviewing a local or
hosted build. The script runs only in the current page, stores
annotations in memory, and makes no network requests after it has loaded.

### Serve a local build

If you are reviewing a local publisher build, serve the generated output over
HTTP rather than opening the files directly from disk:

```bash
cd output/en
python3 -m http.server 8000
```

Then open `http://127.0.0.1:8000/`.

### Create the bookmarklet

Use this bookmarklet. It loads the annotator from the HL7 CI build of this IG
after this file has been published there:

```javascript
javascript:(()=>{const u='https://build.fhir.org/ig/HL7/bulk-data/branches/argo25/en/llm-dom-annotator.js';if(window.LlmDomAnnotator){window.LlmDomAnnotator.activate();return;}const s=document.createElement('script');s.src=u+'?'+Date.now();s.onload=()=>window.LlmDomAnnotator?.activate();document.documentElement.appendChild(s);})()
```

To test unpublished local changes to the annotator, use the script from a local
Publisher build instead:

```javascript
javascript:(()=>{const u='http://127.0.0.1:8000/llm-dom-annotator.js';if(window.LlmDomAnnotator){window.LlmDomAnnotator.activate();return;}const s=document.createElement('script');s.src=u+'?'+Date.now();s.onload=()=>window.LlmDomAnnotator?.activate();document.documentElement.appendChild(s);})()
```

This works for both local pages served from `http://127.0.0.1:8000/` and hosted
HTTPS IG pages, provided the page does not block injected scripts with a Content
Security Policy.

### Install the bookmarklet

#### Chrome, Edge, and Brave

1. Show the bookmarks bar with `Ctrl+Shift+B` on Windows/Linux or
   `Cmd+Shift+B` on macOS.
2. Right-click the bookmarks bar and select **Add page**.
3. Name it `Annotate`.
4. Paste the bookmarklet code into the **URL** field.
5. Save it.

#### Firefox

1. Show the bookmarks toolbar from **View > Toolbars > Bookmarks Toolbar**.
2. Right-click the toolbar and select **Add Bookmark**.
3. Name it `Annotate`.
4. Paste the bookmarklet code into the **URL** field.
5. Save it.

#### Safari

1. Show the Favorites bar from **View > Show Favorites Bar**.
2. Add any page to Favorites.
3. Open **Bookmarks > Edit Bookmarks**.
4. Rename the bookmark to `Annotate`.
5. Replace its address with the bookmarklet code.

### Use the annotator

1. Open the IG page you want to review.
2. Click the `Annotate` bookmarklet.
3. Use the `annotations` panel to add, edit, summarize, and copy annotations.
4. Copy the summary before navigating away or refreshing the page.

The keyboard shortcut `Ctrl+Shift+A` or `Cmd+Shift+A` also activates the tool
after it has been loaded on the page.
