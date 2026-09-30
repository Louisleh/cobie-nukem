/* Root-side request builder only. Never install a retained measurement probe.
 * Chrome evaluate_script.args are snapshot element UIDs, not literal anchors.
 */
'use strict';

function readSampler(timeOriginArg, baselineNowArg) {
  const now = performance.now();
  const origin = performance.timeOrigin;
  const baseOrigin = timeOriginArg === undefined ? origin : timeOriginArg;
  const baseNow = baselineNowArg === undefined ? now : baselineNowArg;
  const helper = globalThis.__cnMultiTouch;
  if (!helper) throw new Error('Missing frozen public-input helper');
  const state = helper.state();
  const memory = performance.memory;
  const finite = value => Number.isFinite(value) ? value : null;
  return {
    timeOrigin: origin, now, elapsedMs: now - baseNow,
    sameDocumentOrigin: origin === baseOrigin,
    visibility: document.visibilityState, hasFocus: document.hasFocus(),
    viewportWidth: innerWidth, viewportHeight: innerHeight, dpr: devicePixelRatio,
    helperActiveCount: state.activeCount, helperTracing: state.tracing,
    helperTraceCount: state.traceCount, helperTraceCapacity: state.traceCapacity,
    memorySupported: Boolean(memory),
    usedJSHeapSize: memory ? finite(memory.usedJSHeapSize) : null,
    totalJSHeapSize: memory ? finite(memory.totalJSHeapSize) : null,
    jsHeapSizeLimit: memory ? finite(memory.jsHeapSizeLimit) : null,
    memoryScope: 'optional coarse Chrome JS; native/GPU/precision OPEN'
  };
}

function numericLiteral(value, name) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
    throw new TypeError(`${name} must be a finite nonnegative number`);
  }
  return JSON.stringify(value);
}

function buildSamplerFunction(anchor = null) {
  if (anchor !== null && (typeof anchor !== 'object' || Array.isArray(anchor))) {
    throw new TypeError('Anchor must be a baseline record or null');
  }
  const literals = anchor === null ? [] : [
    numericLiteral(anchor.timeOrigin, 'timeOrigin'),
    numericLiteral(anchor.now, 'baseline now')
  ];
  // The function carries only reviewed stateless code and finite numeric data.
  // No page argument handles, new global, timer, listener or sample history.
  return `() => (${readSampler.toString()})(${literals.join(', ')})`;
}

function buildEvaluateRequest({pageId, filePath, anchor = null}) {
  if (!Number.isInteger(pageId) || pageId < 1) throw new TypeError('Invalid pageId');
  if (typeof filePath !== 'string' || !filePath.trim()) throw new TypeError('Missing external filePath');
  return {pageId, filePath, function: buildSamplerFunction(anchor), waitForStableDom: false};
}

module.exports = {buildSamplerFunction, buildEvaluateRequest};
