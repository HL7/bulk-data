# Tools

This page describes optional reviewer tooling for annotating generated IG pages.
These tools are not part of the published specification.

## LLM DOM Annotator Bookmarklet

The LLM DOM Annotator is maintained in this repository at
`input/images/llm-dom-annotator.js`. The IG Publisher copies this file to the
published output so it can be loaded as a bookmarklet when reviewing a local or
hosted build. This works for both local pages served from `http://127.0.0.1:8000/` and hosted
HTTPS IG pages, provided the page does not block injected scripts with a Content
Security Policy.

The script runs only in the current page, stores
annotations in memory, and makes no network requests after it has loaded.

### Install the annotator

#### Bookmarklet Code

```text
javascript:(function(){var w=window,d=document,l=w.location,p=l.pathname;if(!/\/$/.test(p)){p=/\.[^\/.]+$/.test(p)?p.replace(/[^\/]*$/,''):p+'/';}var u=l.protocol+'//'+l.host+p+'llm-dom-annotator.js';if(w.LlmDomAnnotator){w.LlmDomAnnotator.activate();return;}var s=d.createElement('script');s.src=u+'?'+Date.now();s.onload=function(){if(w.LlmDomAnnotator)w.LlmDomAnnotator.activate();};s.onerror=function(){alert('Could not load LLM DOM Annotator: '+u);};d.documentElement.appendChild(s);}())
```

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
