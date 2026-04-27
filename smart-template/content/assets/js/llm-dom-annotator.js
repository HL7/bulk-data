/*
LLM DOM Annotator

A dependency-free, in-page annotation helper for collecting precise website
change requests for an LLM agent. It lets a reviewer activate a draggable
annotation pill, select DOM elements, write instructions, edit/import
annotations, and copy an LLM-ready summary with selectors, text, bounds, and
optional full DOM details.

Summary output options:
- REPORT_MODE: "compact" or "full"
  - "compact" includes instructions, selectors, text, role/name, and bounds.
  - "full" also includes attributes, computed style, and nearby HTML.
- REPORT_FORMAT: "text", "json", or "both"
  - "text" is the default human-readable prompt format.
  - "json" returns only machine-readable JSON.
  - "both" appends fenced JSON after the text summary.
- You can also set window.LlmDomAnnotatorConfig = { reportMode, reportFormat }
  before loading the script.

Integration:
- Add this file to a page with:
  <script src="/path/to/llm-dom-annotator.js" defer></script>
- Or load it from the console/bookmarklet on a page you are reviewing.
- Reviewers press Ctrl+Shift+A, Cmd+Shift+A, or call:
  window.LlmDomAnnotator.activate()
- The script keeps annotations in memory only. It makes no network requests.
- Use the Copy button before leaving the page. The script warns before
  navigation/reload when annotations exist and the current summary has not been
  copied.

Public API:
- window.LlmDomAnnotator.activate()
- window.LlmDomAnnotator.deactivate()
- window.LlmDomAnnotator.toggle()
- window.LlmDomAnnotator.copy()
- window.LlmDomAnnotator.clear()
- window.LlmDomAnnotator.importReport(summaryText)
- window.LlmDomAnnotator.buildReport({ mode, format })
*/

(() => {
  "use strict";

  const GLOBAL_NAME = "LlmDomAnnotator";
  const REPORT_MODE = "compact"; // "compact" or "full"
  const REPORT_FORMAT = "text"; // "text", "json", or "both"
  const MODIFIER_HINT = /Mac|iPhone|iPad|iPod/.test(navigator.platform)
    ? "Cmd+Shift+A"
    : "Ctrl+Shift+A";

  if (window[GLOBAL_NAME] && typeof window[GLOBAL_NAME].destroy === "function") {
    window[GLOBAL_NAME].destroy();
  }

  const state = {
    active: false,
    root: null,
    shadow: null,
    toolbar: null,
    highlighter: null,
    modal: null,
    navigationModal: null,
    copyModal: null,
    editModal: null,
    hovered: null,
    selecting: false,
    annotations: [],
    markers: new Map(),
    nextId: 1,
    listeners: [],
    reportCopied: true,
    lastCopiedAt: null,
    allowNavigationOnce: false,
  };

  const navigationWarning =
    "You have annotations that have not been copied. Leave this page anyway?";

  const skipSelector = [
    "html",
    "body",
    "script",
    "style",
    "link",
    "meta",
    "title",
    "noscript",
  ].join(",");

  const css = `
    :host {
      all: initial;
      color-scheme: light;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      --lda-blue: #2563eb;
      --lda-blue-dark: #1d4ed8;
      --lda-bg: #111827;
      --lda-border: rgba(255, 255, 255, 0.14);
      --lda-text: #f9fafb;
      --lda-muted: #9ca3af;
      --lda-panel: #ffffff;
      --lda-panel-text: #111827;
      --lda-panel-muted: #6b7280;
      --lda-panel-border: #d1d5db;
      --lda-danger: #dc2626;
      --lda-success: #15803d;
    }

    .lda-pill {
      position: fixed;
      right: 16px;
      bottom: 16px;
      z-index: 2147483647;
      display: flex;
      align-items: center;
      gap: 8px;
      min-height: 42px;
      padding: 8px 9px;
      border: 1px solid var(--lda-border);
      border-radius: 8px;
      background: var(--lda-bg);
      color: var(--lda-text);
      box-shadow: 0 18px 50px rgba(0, 0, 0, 0.28);
      font-size: 13px;
      line-height: 1;
      pointer-events: auto;
      user-select: none;
    }

    .lda-drag-handle {
      appearance: none;
      display: grid;
      width: 28px;
      height: 28px;
      place-items: center;
      border: 0;
      border-radius: 0;
      background: transparent;
      color: var(--lda-muted);
      cursor: grab;
      font: inherit;
      font-size: 15px;
      font-weight: 800;
      line-height: 1;
      padding: 0;
      touch-action: none;
    }

    .lda-drag-handle:active {
      cursor: grabbing;
    }

    .lda-pill-title {
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0;
      white-space: nowrap;
    }

    .lda-pill-meta {
      color: var(--lda-muted);
      font-size: 12px;
      white-space: nowrap;
    }

    .lda-pill-actions {
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .lda-button {
      appearance: none;
      min-height: 28px;
      border: 1px solid rgba(255, 255, 255, 0.18);
      border-radius: 6px;
      background: rgba(255, 255, 255, 0.08);
      color: var(--lda-text);
      cursor: pointer;
      font: inherit;
      font-size: 12px;
      font-weight: 650;
      line-height: 1;
      padding: 0 9px;
    }

    .lda-button:hover {
      background: rgba(255, 255, 255, 0.16);
    }

    .lda-button-primary {
      border-color: var(--lda-blue);
      background: var(--lda-blue);
      color: #fff;
    }

    .lda-button-primary:hover {
      background: var(--lda-blue-dark);
    }

    .lda-button-danger {
      color: #fecaca;
    }

    .lda-highlighter {
      position: fixed;
      z-index: 2147483646;
      display: none;
      border: 2px solid var(--lda-blue);
      border-radius: 4px;
      background: rgba(37, 99, 235, 0.08);
      box-shadow: 0 0 0 99999px rgba(15, 23, 42, 0.02);
      pointer-events: none;
    }

    .lda-highlighter-label {
      position: absolute;
      top: -25px;
      left: -2px;
      max-width: 360px;
      overflow: hidden;
      padding: 4px 7px;
      border-radius: 5px 5px 5px 0;
      background: var(--lda-blue);
      color: #fff;
      font-size: 12px;
      font-weight: 700;
      line-height: 1;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .lda-marker {
      position: fixed;
      z-index: 2147483645;
      display: grid;
      width: 24px;
      height: 24px;
      place-items: center;
      border: 2px solid #fff;
      border-radius: 999px;
      background: #ef4444;
      color: #fff;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
      font-size: 12px;
      font-weight: 800;
      line-height: 1;
      cursor: pointer;
      pointer-events: auto;
      transform: translate(-50%, -50%);
    }

    .lda-modal {
      position: fixed;
      top: 50%;
      left: 50%;
      z-index: 2147483647;
      width: 520px;
      max-width: calc(100vw - 32px);
      border: 1px solid var(--lda-panel-border);
      border-radius: 8px;
      background: var(--lda-panel);
      color: var(--lda-panel-text);
      box-shadow: 0 26px 80px rgba(0, 0, 0, 0.34);
      pointer-events: auto;
      transform: translate(-50%, -50%);
    }

    .lda-modal-header,
    .lda-modal-footer {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      padding: 14px;
    }

    .lda-modal-header {
      border-bottom: 1px solid #e5e7eb;
    }

    .lda-modal-title {
      min-width: 0;
      margin: 0;
      font-size: 14px;
      font-weight: 750;
      line-height: 1.25;
    }

    .lda-modal-subtitle {
      display: block;
      max-width: 440px;
      overflow: hidden;
      margin-top: 3px;
      color: var(--lda-panel-muted);
      font-size: 12px;
      font-weight: 500;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .lda-close {
      appearance: none;
      width: 30px;
      height: 30px;
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      background: #fff;
      color: #374151;
      cursor: pointer;
      font-size: 20px;
      line-height: 1;
    }

    .lda-modal-body {
      padding: 14px;
    }

    .lda-field-label {
      display: block;
      margin-bottom: 7px;
      color: #374151;
      font-size: 12px;
      font-weight: 750;
    }

    .lda-label-row {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      gap: 6px;
      margin-bottom: 7px;
    }

    .lda-label-row .lda-field-label {
      margin-bottom: 0;
    }

    .lda-textarea {
      box-sizing: border-box;
      width: 100%;
      min-height: 132px;
      resize: vertical;
      border: 1px solid var(--lda-panel-border);
      border-radius: 7px;
      color: #111827;
      font: 14px/1.45 ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      padding: 10px;
      outline: none;
    }

    .lda-textarea:focus {
      border-color: var(--lda-blue);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.14);
    }

	    .lda-copy-textarea {
	      min-height: 220px;
	      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
	      font-size: 11px;
	      line-height: 1.35;
	      white-space: pre;
	    }

    .lda-edit-textarea {
      min-height: min(56vh, 520px);
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      font-size: 11px;
      line-height: 1.35;
      white-space: pre;
    }

    .lda-element-summary {
      display: grid;
      gap: 5px;
      margin-top: 10px;
      padding: 10px;
      border-radius: 7px;
      background: #f9fafb;
      color: #374151;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      font-size: 11px;
      line-height: 1.35;
    }

    .lda-modal-footer {
      border-top: 1px solid #e5e7eb;
    }

    .lda-help {
      color: var(--lda-panel-muted);
      font-size: 12px;
    }

    .lda-error {
      color: var(--lda-danger);
      font-size: 12px;
      font-weight: 700;
    }

    .lda-light-button,
    .lda-save-button {
      appearance: none;
      min-height: 32px;
      border: 1px solid #d1d5db;
      border-radius: 6px;
      background: #fff;
      color: #111827;
      cursor: pointer;
      font: inherit;
      font-size: 13px;
      font-weight: 700;
      padding: 0 11px;
    }

    .lda-save-button {
      border-color: var(--lda-blue);
      background: var(--lda-blue);
      color: #fff;
    }

    .lda-save-button:hover {
      background: var(--lda-blue-dark);
    }

    .lda-big-copy-button {
      min-height: 38px;
      padding: 0 16px;
    }

  `;

  function on(target, type, handler, options) {
    target.addEventListener(type, handler, options);
    state.listeners.push(() => target.removeEventListener(type, handler, options));
  }

  function ensureRoot() {
    if (state.root) return;

    state.root = document.createElement("div");
    state.root.setAttribute("data-llm-dom-annotator-root", "");
    state.root.style.position = "fixed";
    state.root.style.inset = "0";
    state.root.style.zIndex = "2147483647";
    state.root.style.pointerEvents = "none";
    document.documentElement.appendChild(state.root);

    state.shadow = state.root.attachShadow({ mode: "open" });
    const style = document.createElement("style");
    style.textContent = css;
    state.shadow.appendChild(style);

    state.highlighter = document.createElement("div");
    state.highlighter.className = "lda-highlighter";
    state.highlighter.innerHTML = '<div class="lda-highlighter-label"></div>';
    state.shadow.appendChild(state.highlighter);
  }

  function activate() {
    if (state.active) return;
    ensureRoot();
    state.active = true;
    renderToolbar();
    on(document, "mousemove", handleMouseMove, true);
    on(document, "click", handleClick, true);
    on(window, "scroll", updateMarkers, true);
    on(window, "resize", updateMarkers, true);
    updateMarkers();
  }

  function deactivate() {
    if (!state.active) return;
    state.active = false;
    state.selecting = false;
    state.hovered = null;
    state.listeners.splice(0).forEach((off) => off());
    if (state.highlighter) state.highlighter.style.display = "none";
    if (state.toolbar) state.toolbar.remove();
    state.toolbar = null;
    closeModal();
    closeNavigationGuard();
    closeCopyFallback();
    closeEditDialog();
    updateMarkers();
  }

  function toggle() {
    state.active ? deactivate() : activate();
  }

  function destroy() {
    deactivate({ silent: true });
    document.removeEventListener("keydown", handleGlobalKeyDown, true);
    document.removeEventListener("click", handleNavigationClick, true);
    document.removeEventListener("submit", handleNavigationSubmit, true);
    window.removeEventListener("beforeunload", handleBeforeUnload);
    if (state.root) state.root.remove();
    state.root = null;
    state.shadow = null;
    state.highlighter = null;
    state.navigationModal = null;
    state.copyModal = null;
    state.editModal = null;
    state.markers.clear();
    delete window[GLOBAL_NAME];
  }

  function renderToolbar() {
    ensureRoot();
    if (!state.toolbar) {
      state.toolbar = document.createElement("div");
      state.toolbar.className = "lda-pill";
      state.shadow.appendChild(state.toolbar);
    }

    state.toolbar.innerHTML = `
      <button class="lda-drag-handle" type="button" data-action="drag" aria-label="Move annotations panel">⋮⋮</button>
      <strong class="lda-pill-title">annotations</strong>
      <span class="lda-pill-meta">${state.annotations.length}</span>
      <div class="lda-pill-actions">
        <button class="lda-button lda-button-primary" type="button" data-action="add">Add</button>
        <button class="lda-button" type="button" data-action="edit">Summary</button>
        ${hasUncopiedAnnotations() ? '<button class="lda-button" type="button" data-action="copy">Copy</button>' : ""}
      </div>
    `;

    const addButton = state.toolbar.querySelector('[data-action="add"]');
    let addHandledByPointer = false;
    state.toolbar.querySelector('[data-action="drag"]').addEventListener("pointerdown", handlePillDragStart);
    addButton.addEventListener("pointerdown", (event) => {
      event.preventDefault();
      addHandledByPointer = true;
      beginAddAnnotation();
    });
    addButton.addEventListener("click", () => {
      if (addHandledByPointer) {
        addHandledByPointer = false;
        return;
      }
      beginAddAnnotation();
    });
    state.toolbar.querySelector('[data-action="edit"]').addEventListener("click", () => {
      openEditDialog();
    });
    state.toolbar.querySelector('[data-action="copy"]')?.addEventListener("click", () => {
      copyReport();
    });
  }

  function handlePillDragStart(event) {
    if (!state.toolbar) return;
    event.preventDefault();
    const handle = event.currentTarget;
    const rect = state.toolbar.getBoundingClientRect();
    const offsetX = event.clientX - rect.left;
    const offsetY = event.clientY - rect.top;

    state.toolbar.style.right = "auto";
    state.toolbar.style.bottom = "auto";
    state.toolbar.style.left = `${rect.left}px`;
    state.toolbar.style.top = `${rect.top}px`;

    const move = (moveEvent) => {
      if (moveEvent.pointerId !== event.pointerId) return;
      const nextLeft = clampNumber(moveEvent.clientX - offsetX, 8, window.innerWidth - rect.width - 8);
      const nextTop = clampNumber(moveEvent.clientY - offsetY, 8, window.innerHeight - rect.height - 8);
      state.toolbar.style.left = `${nextLeft}px`;
      state.toolbar.style.top = `${nextTop}px`;
    };
    const stop = (stopEvent) => {
      if (stopEvent.pointerId !== event.pointerId) return;
      handle.releasePointerCapture?.(event.pointerId);
      handle.removeEventListener("pointermove", move, true);
      handle.removeEventListener("pointerup", stop, true);
      handle.removeEventListener("pointercancel", stop, true);
    };

    handle.setPointerCapture?.(event.pointerId);
    handle.addEventListener("pointermove", move, true);
    handle.addEventListener("pointerup", stop, true);
    handle.addEventListener("pointercancel", stop, true);
  }

  function beginAddAnnotation() {
    activate();
    closeModal();
    closeEditDialog();
    closeCopyFallback();
    closeNavigationGuard();

    const selectedTextTarget = selectedTextTargetElement();
    if (selectedTextTarget) {
      const annotation = findExactAnnotationForElement(selectedTextTarget.element);
      openModal(
        selectedTextTarget.element,
        annotation,
        {
          initialInstruction: annotation
            ? appendParagraph(annotation.instruction, selectedTextTarget.text)
            : selectedTextTarget.text,
        },
      );
      return;
    }

    state.selecting = true;
    state.hovered = null;
    drawHighlighter(null);
  }

  function cancelSelection() {
    if (!state.selecting) return false;
    state.selecting = false;
    state.hovered = null;
    drawHighlighter(null);
    return true;
  }

  function handleGlobalKeyDown(event) {
    const activationShortcut =
      event.shiftKey &&
      (event.ctrlKey || event.metaKey) &&
      event.key.toLowerCase() === "a";

    if (activationShortcut) {
      event.preventDefault();
      event.stopPropagation();
      if (state.active) {
        beginAddAnnotation();
      } else {
        activate();
      }
      return;
    }

    if (!state.active) return;

    if (event.key === "Escape") {
      event.preventDefault();
      cancelSelection() || closeModal() || closeEditDialog() || closeCopyFallback() || closeNavigationGuard();
      return;
    }
  }

  function handleBeforeUnload(event) {
    if (state.allowNavigationOnce || !hasUncopiedAnnotations()) return;
    event.preventDefault();
    event.returnValue = "";
    return "";
  }

  function handleNavigationClick(event) {
    if (event.defaultPrevented) return;
    if (isOverlayEvent(event)) return;

    const target = event.target instanceof Element ? event.target : null;
    const anchor = target?.closest("a[href]");
    if (!anchor) return;

    if (isActivationLink(anchor)) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      activate();
      return;
    }

    if (state.selecting || !hasUncopiedAnnotations()) return;
    if (anchor.hasAttribute("download")) return;
    if (anchor.target && anchor.target.toLowerCase() !== "_self") return;

    const href = anchor.getAttribute("href") || "";
    if (!href || href.startsWith("javascript:")) return;

    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();

    showNavigationGuard(() => {
      state.allowNavigationOnce = !isSameDocumentUrl(anchor.href);
      navigateToUrl(anchor.href);
      if (isSameDocumentUrl(anchor.href)) state.allowNavigationOnce = false;
    });
  }

  function handleNavigationSubmit(event) {
    if (!hasUncopiedAnnotations() || event.defaultPrevented) return;
    if (isOverlayEvent(event)) return;

    const form = event.target instanceof HTMLFormElement ? event.target : null;
    if (!form) return;

    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();

    showNavigationGuard(() => {
      state.allowNavigationOnce = true;
      HTMLFormElement.prototype.submit.call(form);
    });
  }

  function handleMouseMove(event) {
    if (!state.active || !state.selecting || isOverlayEvent(event)) return;
    const el = selectableElement(event.target);
    const annotation = findExactAnnotationForElement(el);
    state.hovered = el;
    drawHighlighter(el, annotation);
  }

  function handleClick(event) {
    if (!state.active || !state.selecting || isOverlayEvent(event)) return;
    const el = selectableElement(event.target);
    if (!el) return;
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
    state.selecting = false;
    drawHighlighter(null);
    const annotation = findExactAnnotationForElement(el);
    openModal(el, annotation);
  }

  function selectableElement(target) {
    if (!target || target === window || target === document) return null;
    const el = target.nodeType === Node.TEXT_NODE ? target.parentElement : target;
    if (!(el instanceof Element)) return null;
    if (el.closest("[data-llm-dom-annotator-root]")) return null;
    if (el.matches(skipSelector)) return null;
    return el;
  }

  function selectedTextTargetElement() {
    const selection = window.getSelection?.();
    const selectedText = normalizeWhitespace(selection?.toString() || "");
    if (!selection || selection.rangeCount === 0 || !selectedText) return null;

    const range = selection.getRangeAt(0);
    const container = range.commonAncestorContainer;
    const element =
      container.nodeType === Node.TEXT_NODE
        ? container.parentElement
        : container instanceof Element
          ? container
          : null;
    const selectable = selectableElement(element);
    if (!selectable) return null;

    return {
      element: selectable,
      text: selectedText,
    };
  }

  function findAnnotationForElement(el) {
    if (!el) return null;

    const exact = findExactAnnotationForElement(el);
    if (exact) return exact;

    return (
      state.annotations
        .filter((annotation) => annotation.element?.contains(el))
        .sort((left, right) => nodeDepth(right.element) - nodeDepth(left.element))[0] || null
    );
  }

  function findExactAnnotationForElement(el) {
    if (!el) return null;
    return state.annotations.find((annotation) => annotation.element === el) || null;
  }

  function nodeDepth(el) {
    let depth = 0;
    let current = el;
    while (current?.parentElement) {
      depth += 1;
      current = current.parentElement;
    }
    return depth;
  }

  function isOverlayEvent(event) {
    return event.composedPath().some((node) => node === state.root);
  }

  function drawHighlighter(el, annotation) {
    if (!state.highlighter) return;
    if (!el) {
      state.highlighter.style.display = "none";
      return;
    }

    const rect = el.getBoundingClientRect();
    if (!rect.width || !rect.height) {
      state.highlighter.style.display = "none";
      return;
    }

    Object.assign(state.highlighter.style, {
      display: "block",
      left: `${Math.max(0, rect.left)}px`,
      top: `${Math.max(0, rect.top)}px`,
      width: `${rect.width}px`,
      height: `${rect.height}px`,
    });

    const label = state.highlighter.querySelector(".lda-highlighter-label");
    label.textContent = highlighterLabel(el, annotation);
  }

  function highlighterLabel(el, annotation) {
    const bits = [el.tagName.toLowerCase()];
    if (el.id) bits.push(`#${el.id}`);
    const classes = Array.from(el.classList || []).slice(0, 2);
    if (classes.length) bits.push(`.${classes.join(".")}`);
    const text = getElementText(el, 60);
    const label = text ? `${bits.join("")} - "${text}"` : bits.join("");
    return annotation ? `Edit annotation #${annotation.id}: ${label}` : label;
  }

  function openModal(el, annotation = null, options = {}) {
    ensureRoot();
    closeModal();

    const details = analyzeElement(el);
    const isEditing = Boolean(annotation);
    state.modal = document.createElement("div");
    state.modal.className = "lda-modal";
    state.modal.innerHTML = `
      <div class="lda-modal-header">
        <div>
          <h2 class="lda-modal-title">${isEditing ? `Edit annotation #${annotation.id}` : `Add instruction for ${escapeHtml(details.label)}`}</h2>
          <span class="lda-modal-subtitle">${escapeHtml(details.selector)}</span>
        </div>
        <button class="lda-close" type="button" aria-label="Close">&times;</button>
      </div>
      <div class="lda-modal-body">
        <div class="lda-label-row">
          <label class="lda-field-label" for="lda-instruction">What should the LLM change?</label>
        </div>
        <textarea class="lda-textarea" id="lda-instruction" placeholder="Example: Replace this heading with &quot;Simple pricing for growing teams&quot;."></textarea>
        <div class="lda-element-summary">
          <div>text: ${escapeHtml(details.text || "(none)")}</div>
          <div>bounds: x=${details.bounds.document.x}, y=${details.bounds.document.y}, w=${details.bounds.document.width}, h=${details.bounds.document.height}</div>
          <div>role/name: ${escapeHtml(details.role || "(none)")}/${escapeHtml(details.accessibleName || "(none)")}</div>
        </div>
      </div>
      <div class="lda-modal-footer">
        <span></span>
        <div>
          ${isEditing ? '<button class="lda-light-button" type="button" data-action="delete">Delete</button>' : ""}
          <button class="lda-light-button" type="button" data-action="cancel">Cancel</button>
          <button class="lda-save-button" type="button" data-action="save">Save annotation</button>
        </div>
      </div>
    `;
    state.shadow.appendChild(state.modal);

    const textarea = state.modal.querySelector("textarea");
    textarea.value = options.initialInstruction ?? annotation?.instruction ?? "";

    const save = () => {
      const textValue = textarea.value.trim();
      if (!textValue) {
        textarea.focus();
        return;
      }
      if (annotation) {
        updateAnnotation(annotation, textValue, undefined);
      } else {
        addAnnotation(el, textValue, undefined);
      }
      closeModal();
      renderToolbar();
    };

    state.modal.querySelector(".lda-close").addEventListener("click", closeModal);
    state.modal.querySelector('[data-action="cancel"]').addEventListener("click", closeModal);
    state.modal.querySelector('[data-action="delete"]')?.addEventListener("click", () => {
      deleteAnnotation(annotation);
      closeModal();
      renderToolbar();
    });
    state.modal.querySelector('[data-action="save"]').addEventListener("click", save);

    textarea.addEventListener("keydown", (event) => {
      if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
        event.preventDefault();
        save();
      }
    });
    setTimeout(() => textarea.focus(), 0);
  }

  function closeModal() {
    if (!state.modal) return false;
    state.modal.remove();
    state.modal = null;
    return true;
  }

  function showNavigationGuard(onLeave) {
    ensureRoot();
    closeNavigationGuard();

    state.navigationModal = document.createElement("div");
    state.navigationModal.className = "lda-modal";
    state.navigationModal.innerHTML = `
      <div class="lda-modal-header">
        <div>
          <h2 class="lda-modal-title">Uncopied annotation summary</h2>
          <span class="lda-modal-subtitle">${escapeHtml(navigationWarning)}</span>
        </div>
        <button class="lda-close" type="button" aria-label="Close">&times;</button>
      </div>
      <div class="lda-modal-body">
        <p class="lda-help" style="margin: 0; color: #374151; line-height: 1.45;">
          You have ${state.annotations.length} annotation${state.annotations.length === 1 ? "" : "s"} in memory.
          Copy the summary before leaving, or continue and lose the current annotations.
        </p>
      </div>
      <div class="lda-modal-footer">
        <span class="lda-help">Navigation is paused.</span>
        <div>
          <button class="lda-light-button" type="button" data-action="stay">Stay</button>
          <button class="lda-light-button" type="button" data-action="copy">Copy summary</button>
          <button class="lda-save-button" type="button" data-action="leave">Leave</button>
        </div>
      </div>
    `;
    state.shadow.appendChild(state.navigationModal);

    state.navigationModal.querySelector(".lda-close").addEventListener("click", closeNavigationGuard);
    state.navigationModal.querySelector('[data-action="stay"]').addEventListener("click", closeNavigationGuard);
    state.navigationModal.querySelector('[data-action="copy"]').addEventListener("click", async () => {
      await copyReport();
      closeNavigationGuard();
    });
    state.navigationModal.querySelector('[data-action="leave"]').addEventListener("click", () => {
      closeNavigationGuard();
      onLeave();
    });
  }

  function closeNavigationGuard() {
    if (!state.navigationModal) return false;
    state.navigationModal.remove();
    state.navigationModal = null;
    return true;
  }

  function openCopyFallback(report, error) {
    ensureRoot();
    closeCopyFallback();

    state.copyModal = document.createElement("div");
    state.copyModal.className = "lda-modal";
    state.copyModal.innerHTML = `
      <div class="lda-modal-header">
        <div>
          <h2 class="lda-modal-title">Copy summary manually</h2>
          <span class="lda-modal-subtitle">${escapeHtml(error?.message || String(error || "Clipboard copy failed"))}</span>
        </div>
        <button class="lda-close" type="button" aria-label="Close">&times;</button>
      </div>
      <div class="lda-modal-body">
        <label class="lda-field-label" for="lda-copy-report">Summary text</label>
        <textarea class="lda-textarea lda-copy-textarea" id="lda-copy-report" readonly></textarea>
      </div>
      <div class="lda-modal-footer">
        <span class="lda-help">Summary is selected. Press ${escapeHtml(MODIFIER_HINT.replace("Shift+A", "C"))} to copy.</span>
        <div>
          <button class="lda-light-button" type="button" data-action="close">Close</button>
          <button class="lda-save-button" type="button" data-action="retry">Try copy again</button>
        </div>
      </div>
    `;
    state.shadow.appendChild(state.copyModal);

    const textarea = state.copyModal.querySelector("textarea");
    textarea.value = report;
    textarea.focus({ preventScroll: true });
    textarea.select();

    state.copyModal.querySelector(".lda-close").addEventListener("click", closeCopyFallback);
    state.copyModal.querySelector('[data-action="close"]').addEventListener("click", closeCopyFallback);
    state.copyModal.querySelector('[data-action="retry"]').addEventListener("click", async () => {
      try {
        await writeClipboard(report);
        markReportCopied();
        if (state.active) renderToolbar();
        closeCopyFallback();
      } catch (retryError) {
        const subtitle = state.copyModal?.querySelector(".lda-modal-subtitle");
        if (subtitle) subtitle.textContent = retryError?.message || String(retryError);
        textarea.focus({ preventScroll: true });
        textarea.select();
      }
    });
  }

  function closeCopyFallback() {
    if (!state.copyModal) return false;
    state.copyModal.remove();
    state.copyModal = null;
    return true;
  }

  function openEditDialog() {
    ensureRoot();
    closeEditDialog();

    state.editModal = document.createElement("div");
    state.editModal.className = "lda-modal";
    state.editModal.innerHTML = `
      <div class="lda-modal-header">
        <div>
          <h2 class="lda-modal-title">Edit annotations</h2>
          <span class="lda-modal-subtitle">Edit this text summary, or paste an annotation summary.</span>
        </div>
        <button class="lda-close" type="button" aria-label="Close">&times;</button>
      </div>
      <div class="lda-modal-body">
        <label class="lda-field-label" for="lda-edit-report">Annotation summary</label>
        <textarea class="lda-textarea lda-edit-textarea" id="lda-edit-report" placeholder="Paste an LLM DOM Annotator summary here"></textarea>
        <div class="lda-element-summary">
          Saving replaces the current in-memory annotations. Elements must match this page by selector, XPath, or tag/text.
        </div>
      </div>
      <div class="lda-modal-footer">
        <span class="lda-help" data-role="edit-status"></span>
        <div>
          <button class="lda-save-button lda-big-copy-button" type="button" data-action="copy">Copy summary</button>
          <button class="lda-light-button" type="button" data-action="cancel">Cancel</button>
          <button class="lda-save-button" type="button" data-action="save" hidden>Save</button>
        </div>
      </div>
    `;
    state.shadow.appendChild(state.editModal);

    const textarea = state.editModal.querySelector("textarea");
    const status = state.editModal.querySelector('[data-role="edit-status"]');
    const saveButton = state.editModal.querySelector('[data-action="save"]');
    textarea.value = buildReport({ format: "text" });
    const initialValue = textarea.value;

    const save = () => {
      const reportText = textarea.value.trim();
      if (!reportText) {
        status.className = "lda-error";
        status.textContent = "Paste or enter an annotation summary before saving.";
        textarea.focus();
        return;
      }

      try {
        importAnnotationReport(reportText, { requireResolvedElements: true });
        closeEditDialog();
        renderToolbar();
      } catch (error) {
        status.className = "lda-error";
        status.textContent = error?.message || String(error);
        textarea.focus();
      }
    };

    state.editModal.querySelector(".lda-close").addEventListener("click", closeEditDialog);
    state.editModal.querySelector('[data-action="cancel"]').addEventListener("click", closeEditDialog);
    state.editModal.querySelector('[data-action="copy"]').addEventListener("click", async () => {
      try {
        await writeClipboard(textarea.value);
        markReportCopied();
        renderToolbar();
      } catch (error) {
        status.className = "lda-error";
        status.textContent = error?.message || String(error);
      }
    });
    textarea.addEventListener("input", () => {
      saveButton.hidden = textarea.value === initialValue;
    });
    saveButton.addEventListener("click", save);
    setTimeout(() => textarea.focus(), 0);
  }

  function closeEditDialog() {
    if (!state.editModal) return false;
    state.editModal.remove();
    state.editModal = null;
    return true;
  }

  function importAnnotationReport(reportText, options = {}) {
    const payload = parseAnnotationReport(reportText);
    const importedAnnotations = normalizeImportedAnnotations(payload.annotations || []);
    if (!importedAnnotations.length) {
      throw new Error("No annotations found in the pasted summary.");
    }
    const unresolvedAnnotations = importedAnnotations.filter((annotation) => !annotation.element);
    if (options.requireResolvedElements && unresolvedAnnotations.length) {
      const ids = unresolvedAnnotations.map((annotation) => `#${annotation.id}`).join(", ");
      throw new Error(`These annotations could not be matched to page elements: ${ids}.`);
    }
    const invalidAnnotations = importedAnnotations.filter((annotation) => !annotation.instruction.trim());
    if (invalidAnnotations.length) {
      const ids = invalidAnnotations.map((annotation) => `#${annotation.id}`).join(", ");
      throw new Error(`These annotations are missing instructions: ${ids}.`);
    }

    setImportedAnnotations(importedAnnotations);
    return {
      imported: importedAnnotations.length,
      unresolved: unresolvedAnnotations.length,
    };
  }

  function addAnnotation(el, instruction, change) {
    const details = analyzeElement(el);
    const annotation = {
      id: state.nextId++,
      instruction,
      change,
      capturedAt: new Date().toISOString(),
      element: el,
      details,
    };
    state.annotations.push(annotation);
    markAnnotationsDirty();
    drawMarker(annotation);
    updateMarkers();
    return annotation;
  }

  function updateAnnotation(annotation, instruction, change) {
    annotation.instruction = instruction;
    annotation.change = change;
    annotation.details = analyzeElement(annotation.element);
    markAnnotationsDirty();
    updateMarkers();
    return annotation;
  }

  function deleteAnnotation(annotation) {
    if (!annotation) return false;
    const index = state.annotations.indexOf(annotation);
    if (index < 0) return false;
    state.annotations.splice(index, 1);
    const marker = state.markers.get(annotation.id);
    if (marker) marker.remove();
    state.markers.delete(annotation.id);
    markAnnotationsDirty();
    updateMarkers();
    return true;
  }

  function setImportedAnnotations(annotations) {
    clearAnnotationState();
    state.annotations.push(...annotations);
    state.nextId = Math.max(...annotations.map((annotation) => annotation.id), 0) + 1;
    markAnnotationsDirty();
    for (const annotation of state.annotations) {
      drawMarker(annotation);
    }
    updateMarkers();
  }

  function clearAnnotationState() {
    state.annotations.splice(0);
    state.nextId = 1;
    state.reportCopied = true;
    state.lastCopiedAt = null;
    state.markers.forEach((marker) => marker.remove());
    state.markers.clear();
  }

  function drawMarker(annotation) {
    ensureRoot();
    const marker = document.createElement("div");
    marker.className = "lda-marker";
    marker.setAttribute("role", "button");
    marker.setAttribute("aria-label", `Edit annotation ${annotation.id}`);
    marker.tabIndex = 0;
    marker.textContent = String(annotation.id);
    marker.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      state.selecting = false;
      drawHighlighter(null);
      if (annotation.element) openModal(annotation.element, annotation);
    });
    marker.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" && event.key !== " ") return;
      event.preventDefault();
      if (annotation.element) openModal(annotation.element, annotation);
    });
    state.markers.set(annotation.id, marker);
    state.shadow.appendChild(marker);
  }

  function updateMarkers() {
    for (const annotation of state.annotations) {
      const marker = state.markers.get(annotation.id);
      if (!marker) continue;
      if (!annotation.element || !document.documentElement.contains(annotation.element)) {
        marker.style.display = "none";
        continue;
      }
      const rect = annotation.element.getBoundingClientRect();
      if (!rect.width || !rect.height) {
        marker.style.display = "none";
        continue;
      }
      marker.style.display = state.active ? "grid" : "none";
      marker.style.left = `${rect.left}px`;
      marker.style.top = `${rect.top}px`;
    }
    if (state.active) renderToolbar();
  }

  function clearAnnotations() {
    clearAnnotationState();
    renderToolbar();
  }

  function markAnnotationsDirty() {
    state.reportCopied = false;
    state.lastCopiedAt = null;
  }

  function markReportCopied() {
    state.reportCopied = true;
    state.lastCopiedAt = new Date().toISOString();
  }

  function hasUncopiedAnnotations() {
    return state.annotations.length > 0 && !state.reportCopied;
  }

  function isSameDocumentUrl(url) {
    try {
      const next = new URL(url, location.href);
      return (
        next.origin === location.origin &&
        next.pathname === location.pathname &&
        next.search === location.search
      );
    } catch {
      return false;
    }
  }

  function navigateToUrl(url) {
    if (!isSameDocumentUrl(url)) {
      window.location.href = url;
      return;
    }

    const next = new URL(url, location.href);
    if (next.hash && next.hash !== location.hash) {
      location.hash = next.hash;
    }
  }

  async function copyReport() {
    const report = buildReport();
    try {
      await writeClipboard(report);
      markReportCopied();
      if (state.active) renderToolbar();
    } catch (error) {
      if (state.active) renderToolbar();
      openCopyFallback(report, error);
    }
  }

  async function writeClipboard(text) {
    let clipboardError = null;
    window.focus();

    if (navigator.clipboard && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(text);
        return;
      } catch (error) {
        clipboardError = error;
      }
    }

    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.left = "-9999px";
    document.body.appendChild(textarea);
    textarea.focus({ preventScroll: true });
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();
    if (!copied) {
      throw clipboardError || new Error("clipboard API unavailable");
    }
  }

  function buildReport(options = {}) {
    const config = getReportConfig(options);
    const payload = buildReportPayload(config);

    if (config.format === "json") {
      return JSON.stringify(payload, null, 2);
    }

    const textReport = buildTextReport(payload, config.mode);
    if (config.format === "text") {
      return textReport;
    }

    return [
      textReport,
      "",
      "Machine-readable JSON:",
      "```json",
      JSON.stringify(payload, null, 2),
      "```",
    ].join("\n");
  }

  function getReportConfig(options = {}) {
    const external = window.LlmDomAnnotatorConfig?.report || window.LlmDomAnnotatorConfig || {};
    return {
      mode: normalizeReportMode(
        options.mode || options.reportMode || external.mode || external.reportMode || REPORT_MODE,
      ),
      format: normalizeReportFormat(
        options.format ||
          options.reportFormat ||
          external.format ||
          external.reportFormat ||
          REPORT_FORMAT,
      ),
    };
  }

  function normalizeReportMode(value) {
    const fallback = ["compact", "full"].includes(REPORT_MODE) ? REPORT_MODE : "compact";
    const normalized = String(value || "").toLowerCase();
    return ["compact", "full"].includes(normalized) ? normalized : fallback;
  }

  function normalizeReportFormat(value) {
    const fallback = ["text", "json", "both"].includes(REPORT_FORMAT) ? REPORT_FORMAT : "text";
    const normalized = String(value || "").toLowerCase();
    return ["text", "json", "both"].includes(normalized) ? normalized : fallback;
  }

  function buildReportPayload(config) {
    return {
      report: {
        mode: config.mode,
        format: config.format,
      },
      page: {
        url: location.href,
        title: document.title,
        capturedAt: new Date().toISOString(),
        viewport: {
          width: window.innerWidth,
          height: window.innerHeight,
          deviceScaleFactor: window.devicePixelRatio || 1,
        },
        scroll: {
          x: Math.round(window.scrollX),
          y: Math.round(window.scrollY),
        },
      },
      annotations: state.annotations.map((annotation) => ({
        id: annotation.id,
        instruction: annotation.instruction,
        change: annotation.change || null,
        capturedAt: annotation.capturedAt,
        element:
          config.mode === "full"
            ? annotation.details
            : compactElementDetails(annotation.details),
      })),
    };
  }

  function compactElementDetails(details) {
    return {
      tag: details.tag,
      selector: details.selector,
      xpath: details.xpath,
      role: details.role,
      accessibleName: details.accessibleName,
      text: details.text,
      bounds: details.bounds,
    };
  }

  function buildTextReport(payload, mode) {
    const lines = [
      "# LLM Page Change Request",
      "",
      `URL: ${payload.page.url}`,
      `Title: ${payload.page.title || "(untitled)"}`,
      `Captured: ${payload.page.capturedAt}`,
      `Summary mode: ${mode}`,
      `Viewport: ${payload.page.viewport.width}x${payload.page.viewport.height} @ ${payload.page.viewport.deviceScaleFactor}x`,
      `Scroll: x=${payload.page.scroll.x}, y=${payload.page.scroll.y}`,
      `Annotations: ${payload.annotations.length}`,
      "",
      mode === "full"
        ? "Use the element selectors, text, bounds, attributes, styles, and nearby HTML below to identify the implementation targets. Apply each instruction to the source code that renders the matching UI."
        : "Use the element selectors, text, role/name, and bounds below to identify the implementation targets. Apply each instruction to the source code that renders the matching UI.",
      "",
    ];

    if (!payload.annotations.length) {
      lines.push("_No annotations were added._", "");
    }

    for (const annotation of payload.annotations) {
      const el = annotation.element;
      lines.push(
        `## Annotation ${annotation.id}`,
        "",
        `Instruction: ${annotation.instruction}`,
        "",
      );

      if (annotation.change) {
        lines.push(
          "Text change:",
          `- Type: \`${annotation.change.type}\``,
          `- Original text: ${quoteBlock(annotation.change.originalText || "")}`,
        );
        if (Object.prototype.hasOwnProperty.call(annotation.change, "newText")) {
          lines.push(`- New text: ${quoteBlock(annotation.change.newText || "")}`);
        }
        lines.push("");
      }

      lines.push(
        "Element:",
        `- Tag: \`${el.tag}\``,
        `- Selector: \`${el.selector}\``,
        `- XPath: \`${el.xpath}\``,
        `- Role: ${el.role || "(none)"}`,
        `- Accessible name: ${el.accessibleName || "(none)"}`,
        `- Text: ${quoteBlock(el.text || "(none)")}`,
        `- Viewport bounds: x=${el.bounds.viewport.x}, y=${el.bounds.viewport.y}, w=${el.bounds.viewport.width}, h=${el.bounds.viewport.height}`,
        `- Document bounds: x=${el.bounds.document.x}, y=${el.bounds.document.y}, w=${el.bounds.document.width}, h=${el.bounds.document.height}`,
      );

      if (mode === "full") {
        lines.push(
          `- Classes: ${el.classes.length ? el.classes.map((name) => `\`${name}\``).join(", ") : "(none)"}`,
          `- Attributes: ${formatAttributes(el.attributes)}`,
          "",
          "Computed style:",
          `- display: ${el.computedStyle.display}`,
          `- position: ${el.computedStyle.position}`,
          `- font: ${el.computedStyle.fontWeight} ${el.computedStyle.fontSize}`,
          `- color: ${el.computedStyle.color}`,
          `- background: ${el.computedStyle.backgroundColor}`,
          "",
          "Nearby HTML:",
          "```html",
          el.html,
          "```",
          "",
        );
      } else {
        lines.push("");
      }
    }

    return lines.join("\n");
  }

  function parseAnnotationReport(reportText) {
    const textPayload = parseTextReport(reportText);
    if (textPayload.annotations.length) return textPayload;

    const jsonPayload = parseJsonReport(reportText);
    if (jsonPayload) return jsonPayload;

    throw new Error("Could not parse an annotation summary from the pasted text.");
  }

  function parseJsonReport(reportText) {
    const trimmedReport = reportText.trim();
    const parsedDirectly = tryParseJson(trimmedReport);
    if (parsedDirectly) return normalizeReportPayload(parsedDirectly);

    const fencedJson = trimmedReport.match(/```json\s*([\s\S]*?)```/i);
    if (fencedJson) {
      const parsedFence = tryParseJson(fencedJson[1].trim());
      if (parsedFence) return normalizeReportPayload(parsedFence);
    }

    return null;
  }

  function tryParseJson(value) {
    try {
      return JSON.parse(value);
    } catch {
      return null;
    }
  }

  function normalizeReportPayload(value) {
    if (Array.isArray(value)) return { annotations: value };
    if (value && Array.isArray(value.annotations)) return value;
    return null;
  }

  function parseTextReport(reportText) {
    const annotationSections = reportText
      .split(/\n(?=## Annotation\s+\d+)/)
      .filter((section) => /^## Annotation\s+\d+/m.test(section));

    return {
      annotations: annotationSections.map(parseTextAnnotation).filter(Boolean),
    };
  }

  function parseTextAnnotation(section) {
    const idMatch = section.match(/^## Annotation\s+(\d+)/m);
    const element = parseTextReportElement(section);
    const instruction = extractBetween(section, "Instruction:", [
      "\n\nText change:",
      "\nText change:",
      "\n\nElement:",
      "\nElement:",
    ]);
    const change = parseTextReportChange(section);

    return {
      id: idMatch ? Number.parseInt(idMatch[1], 10) : undefined,
      instruction,
      change,
      element,
    };
  }

  function parseTextReportChange(section) {
    const changeBlock = extractBetween(section, "Text change:", ["\n\nElement:", "\nElement:"]);
    if (!changeBlock) return null;

    const type = extractBacktickLine(changeBlock, "Type") || "unknown";
    const originalText = unquoteBlock(
      extractListValue(changeBlock, "Original text", ["\n- New text:", "\n\n", "\nElement:"]),
    );
    const newTextValue = extractListValue(changeBlock, "New text", ["\n\n", "\nElement:"]);
    const change = {
      type,
      originalText,
    };
    if (newTextValue) change.newText = unquoteBlock(newTextValue);
    return change;
  }

  function parseTextReportElement(section) {
    return {
      tag: extractBacktickLine(section, "Tag"),
      selector: extractBacktickLine(section, "Selector"),
      xpath: extractBacktickLine(section, "XPath"),
      role: normalizeEmptyValue(extractLineValue(section, "Role")),
      accessibleName: normalizeEmptyValue(extractLineValue(section, "Accessible name")),
      text: normalizeEmptyValue(unquoteBlock(extractListValue(section, "Text", ["\n- Viewport bounds:", "\n- Document bounds:", "\n- Classes:", "\n\n"]))),
      bounds: {
        viewport: parseBounds(extractLineValue(section, "Viewport bounds")),
        document: parseBounds(extractLineValue(section, "Document bounds")),
      },
    };
  }

  function normalizeImportedAnnotations(annotations) {
    const usedIds = new Set();
    let fallbackId = 1;

    return annotations.map((annotation) => {
      const elementDetails = normalizeImportedElementDetails(annotation.element || {});
      const element = resolveImportedElement(elementDetails);
      const id = nextImportedId(annotation.id, usedIds, () => {
        while (usedIds.has(fallbackId)) fallbackId += 1;
        return fallbackId;
      });
      usedIds.add(id);
      const change = annotation.change && typeof annotation.change === "object" ? { ...annotation.change } : null;
      const instruction = String(annotation.instruction || "").trim() || String(change?.newText || "").trim();

      return {
        id,
        instruction,
        change,
        capturedAt: annotation.capturedAt || new Date().toISOString(),
        element,
        details: element ? analyzeElement(element) : elementDetails,
      };
    });
  }

  function nextImportedId(value, usedIds, nextFallbackId) {
    const importedId = Number.parseInt(value, 10);
    if (Number.isInteger(importedId) && importedId > 0 && !usedIds.has(importedId)) {
      return importedId;
    }

    return nextFallbackId();
  }

  function normalizeImportedElementDetails(details) {
    const normalizedBounds = normalizeImportedBounds(details.bounds);
    return {
      tag: String(details.tag || "").toLowerCase(),
      selector: String(details.selector || ""),
      xpath: String(details.xpath || ""),
      id: String(details.id || ""),
      classes: Array.isArray(details.classes) ? details.classes : [],
      attributes: details.attributes && typeof details.attributes === "object" ? details.attributes : {},
      role: details.role || "",
      accessibleName: details.accessibleName || "",
      text: details.text || "",
      value: details.value || "",
      bounds: normalizedBounds,
      computedStyle: details.computedStyle && typeof details.computedStyle === "object" ? details.computedStyle : {},
      html: details.html || "",
    };
  }

  function normalizeImportedBounds(bounds) {
    return {
      viewport: normalizeRect(bounds?.viewport),
      document: normalizeRect(bounds?.document),
    };
  }

  function normalizeRect(rect) {
    return {
      x: Number(rect?.x) || 0,
      y: Number(rect?.y) || 0,
      width: Number(rect?.width) || 0,
      height: Number(rect?.height) || 0,
      top: Number(rect?.top ?? rect?.y) || 0,
      right: Number(rect?.right) || 0,
      bottom: Number(rect?.bottom) || 0,
      left: Number(rect?.left ?? rect?.x) || 0,
    };
  }

  function resolveImportedElement(details) {
    const selectorMatch = querySelectorSafely(details.selector);
    if (selectorMatch) return selectorMatch;

    const xpathMatch = queryXpathSafely(details.xpath);
    if (xpathMatch) return xpathMatch;

    return findElementByTagAndText(details.tag, details.text);
  }

  function querySelectorSafely(selector) {
    if (!selector) return null;
    try {
      const match = document.querySelector(selector);
      return match instanceof Element && !match.closest("[data-llm-dom-annotator-root]") ? match : null;
    } catch {
      return null;
    }
  }

  function queryXpathSafely(xpathValue) {
    if (!xpathValue) return null;
    try {
      const result = document.evaluate(xpathValue, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
      const match = result.singleNodeValue;
      return match instanceof Element && !match.closest("[data-llm-dom-annotator-root]") ? match : null;
    } catch {
      return null;
    }
  }

  function findElementByTagAndText(tag, text) {
    if (!tag || !text) return null;
    const normalizedTargetText = normalizeWhitespace(text);
    const candidates = Array.from(document.getElementsByTagName(tag));
    return (
      candidates.find((candidate) => {
        if (candidate.closest("[data-llm-dom-annotator-root]")) return false;
        return normalizeWhitespace(candidate.innerText || candidate.textContent || "") === normalizedTargetText;
      }) || null
    );
  }

  function extractBetween(text, startToken, endTokens) {
    const startIndex = text.indexOf(startToken);
    if (startIndex < 0) return "";
    const contentStart = startIndex + startToken.length;
    let contentEnd = text.length;
    for (const endToken of endTokens) {
      const endIndex = text.indexOf(endToken, contentStart);
      if (endIndex >= 0 && endIndex < contentEnd) contentEnd = endIndex;
    }
    return text.slice(contentStart, contentEnd).trim();
  }

  function extractBacktickLine(text, label) {
    const escapedLabel = escapeRegExp(label);
    const match = text.match(new RegExp("^- " + escapedLabel + ": `([^`]*)`", "m"));
    return match ? match[1] : "";
  }

  function extractLineValue(text, label) {
    const escapedLabel = escapeRegExp(label);
    const match = text.match(new RegExp(`^- ${escapedLabel}:\\s*(.*)$`, "m"));
    return match ? match[1].trim() : "";
  }

  function extractListValue(text, label, endTokens) {
    const startToken = `- ${label}:`;
    return extractBetween(text, startToken, endTokens);
  }

  function parseBounds(value) {
    const match = String(value || "").match(/x=(-?\d+), y=(-?\d+), w=(-?\d+), h=(-?\d+)/);
    if (!match) return normalizeRect(null);
    const parsedX = Number(match[1]) || 0;
    const parsedY = Number(match[2]) || 0;
    const width = Number(match[3]) || 0;
    const height = Number(match[4]) || 0;
    return {
      x: parsedX,
      y: parsedY,
      width,
      height,
      top: parsedY,
      right: parsedX + width,
      bottom: parsedY + height,
      left: parsedX,
    };
  }

  function normalizeEmptyValue(value) {
    const normalized = String(value || "").trim();
    return normalized === "(none)" ? "" : normalized;
  }

  function unquoteBlock(value) {
    const trimmedValue = String(value || "").trim();
    if (trimmedValue === "\"\"") return "";
    if (trimmedValue.startsWith("\"") && trimmedValue.endsWith("\"")) {
      return trimmedValue.slice(1, -1).replace(/\\"/g, "\"");
    }
    return trimmedValue;
  }

  function normalizeWhitespace(value) {
    return String(value || "").replace(/\s+/g, " ").trim();
  }

  function appendParagraph(value, paragraph) {
    const existing = String(value || "").trim();
    const next = String(paragraph || "").trim();
    if (!existing) return next;
    if (!next) return existing;
    return `${existing}\n\n${next}`;
  }

  function clampNumber(value, min, max) {
    return Math.min(Math.max(value, min), Math.max(min, max));
  }

  function escapeRegExp(value) {
    return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  function analyzeElement(el) {
    const rect = el.getBoundingClientRect();
    const style = getComputedStyle(el);
    const tag = el.tagName.toLowerCase();
    const selector = uniqueSelector(el);
    const text = getElementText(el, 500);
    const attributes = interestingAttributes(el);
    const role = el.getAttribute("role") || implicitRole(el);

    return {
      label: highlighterLabel(el),
      tag,
      selector,
      xpath: xpath(el),
      id: el.id || "",
      classes: Array.from(el.classList || []),
      attributes,
      role,
      accessibleName: accessibleName(el),
      text,
      value: elementValue(el),
      bounds: {
        viewport: roundRect(rect, 0, 0),
        document: roundRect(rect, window.scrollX, window.scrollY),
      },
      computedStyle: {
        display: style.display,
        position: style.position,
        color: style.color,
        backgroundColor: style.backgroundColor,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        margin: style.margin,
        padding: style.padding,
      },
      html: htmlSnippet(el),
    };
  }

  function roundRect(rect, offsetX, offsetY) {
    return {
      x: Math.round(rect.left + offsetX),
      y: Math.round(rect.top + offsetY),
      width: Math.round(rect.width),
      height: Math.round(rect.height),
      top: Math.round(rect.top + offsetY),
      right: Math.round(rect.right + offsetX),
      bottom: Math.round(rect.bottom + offsetY),
      left: Math.round(rect.left + offsetX),
    };
  }

  function uniqueSelector(el) {
    const tag = el.tagName.toLowerCase();

    if (el.id) {
      const byId = `#${esc(el.id)}`;
      if (isUnique(byId)) return byId;
      const byTagId = `${tag}${byId}`;
      if (isUnique(byTagId)) return byTagId;
    }

    for (const attr of ["data-testid", "data-test", "data-cy", "name", "aria-label"]) {
      const value = el.getAttribute(attr);
      if (!value) continue;
      const candidate = `${tag}[${attr}="${cssString(value)}"]`;
      if (isUnique(candidate)) return candidate;
    }

    const parts = [];
    let current = el;

    while (current && current.nodeType === Node.ELEMENT_NODE && current !== document.documentElement) {
      let part = current.tagName.toLowerCase();

      if (current.id) {
        part += `#${esc(current.id)}`;
        parts.unshift(part);
        break;
      }

      const classes = Array.from(current.classList || [])
        .filter((name) => !/^(active|selected|hover|focus|open|show|hidden)$/i.test(name))
        .slice(0, 2);
      if (classes.length) part += classes.map((name) => `.${esc(name)}`).join("");

      const parent = current.parentElement;
      if (parent) {
        const sameTag = Array.from(parent.children).filter(
          (child) => child.tagName === current.tagName,
        );
        if (sameTag.length > 1) {
          part += `:nth-of-type(${sameTag.indexOf(current) + 1})`;
        }
      }

      parts.unshift(part);
      const candidate = parts.join(" > ");
      if (isUnique(candidate)) return candidate;
      current = current.parentElement;
    }

    return parts.join(" > ") || tag;
  }

  function isUnique(selector) {
    try {
      return document.querySelectorAll(selector).length === 1;
    } catch {
      return false;
    }
  }

  function xpath(el) {
    if (el.id) return `//*[@id="${el.id.replace(/"/g, '\\"')}"]`;
    const parts = [];
    let current = el;
    while (current && current.nodeType === Node.ELEMENT_NODE) {
      const tag = current.tagName.toLowerCase();
      let index = 1;
      let sibling = current.previousElementSibling;
      while (sibling) {
        if (sibling.tagName === current.tagName) index += 1;
        sibling = sibling.previousElementSibling;
      }
      parts.unshift(`${tag}[${index}]`);
      current = current.parentElement;
    }
    return `/${parts.join("/")}`;
  }

  function interestingAttributes(el) {
    const keep = [
      "id",
      "class",
      "href",
      "src",
      "alt",
      "title",
      "role",
      "aria-label",
      "aria-labelledby",
      "name",
      "type",
      "placeholder",
      "value",
      "data-testid",
      "data-test",
      "data-cy",
    ];
    const out = {};
    for (const attr of keep) {
      const value = el.getAttribute(attr);
      if (value) out[attr] = trim(value, 240);
    }
    for (const attr of Array.from(el.attributes || [])) {
      if (attr.name.startsWith("data-") && !out[attr.name]) {
        out[attr.name] = trim(attr.value, 240);
      }
    }
    return out;
  }

  function accessibleName(el) {
    const aria = el.getAttribute("aria-label");
    if (aria) return trim(aria, 180);

    const labelledBy = el.getAttribute("aria-labelledby");
    if (labelledBy) {
      const text = labelledBy
        .split(/\s+/)
        .map((id) => document.getElementById(id)?.innerText || "")
        .join(" ")
        .trim();
      if (text) return trim(text, 180);
    }

    if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement || el instanceof HTMLSelectElement) {
      const id = el.id;
      const label = id ? document.querySelector(`label[for="${cssString(id)}"]`) : null;
      if (label?.textContent?.trim()) return trim(label.textContent, 180);
      if (el.placeholder) return trim(el.placeholder, 180);
    }

    if (el.getAttribute("alt")) return trim(el.getAttribute("alt"), 180);
    if (el.getAttribute("title")) return trim(el.getAttribute("title"), 180);
    return getElementText(el, 180);
  }

  function implicitRole(el) {
    const tag = el.tagName.toLowerCase();
    if (/^h[1-6]$/.test(tag)) return "heading";
    if (tag === "button") return "button";
    if (tag === "a" && el.hasAttribute("href")) return "link";
    if (tag === "img") return "img";
    if (tag === "nav") return "navigation";
    if (tag === "main") return "main";
    if (tag === "header") return "banner";
    if (tag === "footer") return "contentinfo";
    if (tag === "input") return inputRole(el);
    if (tag === "textarea") return "textbox";
    if (tag === "select") return "combobox";
    return "";
  }

  function inputRole(el) {
    const type = (el.getAttribute("type") || "text").toLowerCase();
    if (type === "checkbox") return "checkbox";
    if (type === "radio") return "radio";
    if (type === "range") return "slider";
    if (type === "button" || type === "submit" || type === "reset") return "button";
    return "textbox";
  }

  function elementValue(el) {
    if ("value" in el && typeof el.value === "string") return trim(el.value, 240);
    return "";
  }

  function getElementText(el, max) {
    const text = (el.innerText || el.textContent || "").replace(/\s+/g, " ").trim();
    return trim(text, max);
  }

  function htmlSnippet(el) {
    const clone = el.cloneNode(true);
    clone.querySelectorAll("script, style, svg, canvas").forEach((node) => {
      if (node.tagName?.toLowerCase() === "svg") {
        node.replaceWith(document.createTextNode("<svg>...</svg>"));
      } else if (node.tagName?.toLowerCase() === "canvas") {
        node.replaceWith(document.createTextNode("<canvas>...</canvas>"));
      } else {
        node.remove();
      }
    });
    return trim(clone.outerHTML.replace(/\s{2,}/g, " "), 1400);
  }

  function formatAttributes(attrs) {
    const entries = Object.entries(attrs);
    if (!entries.length) return "(none)";
    return entries.map(([key, value]) => `\`${key}="${value}"\``).join(", ");
  }

  function quoteBlock(text) {
    if (!text) return "\"\"";
    return `"${text.replace(/"/g, '\\"')}"`;
  }

  function cssString(value) {
    return String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  }

  function esc(value) {
    if (window.CSS && typeof window.CSS.escape === "function") return window.CSS.escape(value);
    return String(value).replace(/[^a-zA-Z0-9_-]/g, (char) => `\\${char}`);
  }

  function trim(value, max) {
    const text = String(value || "").replace(/\s+/g, " ").trim();
    return text.length > max ? `${text.slice(0, max - 1)}...` : text;
  }

  function escapeHtml(value) {
    return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function bindActivationLink() {
    const annotateLink = document.getElementById("llm-dom-annotator-activate");
    if (!annotateLink || annotateLink.dataset.llmDomAnnotatorBound === "true") return;

    annotateLink.dataset.llmDomAnnotatorBound = "true";
    annotateLink.addEventListener("click", (event) => {
      event.preventDefault();
      activate();
    });
  }

  function bindActivationLinkWhenReady() {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bindActivationLink, { once: true });
      return;
    }

    bindActivationLink();
  }

  function isActivationLink(anchor) {
    return anchor.id === "llm-dom-annotator-activate";
  }

  document.addEventListener("keydown", handleGlobalKeyDown, true);
  document.addEventListener("click", handleNavigationClick, true);
  document.addEventListener("submit", handleNavigationSubmit, true);
  window.addEventListener("beforeunload", handleBeforeUnload);
  bindActivationLinkWhenReady();

  window[GLOBAL_NAME] = {
    activate,
    deactivate,
    toggle,
    copy: copyReport,
    clear: clearAnnotations,
    importReport: importAnnotationReport,
    destroy,
    getAnnotations() {
      return state.annotations.map((annotation) => ({
        id: annotation.id,
        instruction: annotation.instruction,
        change: annotation.change || null,
        capturedAt: annotation.capturedAt,
        element: annotation.details,
      }));
    },
    buildReport,
    getReportConfig,
    hasUncopiedAnnotations,
  };

  console.info(
    `[${GLOBAL_NAME}] loaded. Press ${MODIFIER_HINT} or run window.${GLOBAL_NAME}.activate().`,
  );
})();
