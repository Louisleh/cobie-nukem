/* Offline regression for the installed snapshot-UID argument boundary.
 * Fixture constants reproduce actual invalid pair2's baseline JSON values.
 * No browser, Godot, DOM events or production/private engine state is used.
 */
'use strict';
const assert = require('node:assert/strict');
const vm = require('node:vm');
const {buildSamplerFunction, buildEvaluateRequest} = require('./web_retention_sampler.js');
const raw = {
  timeOrigin:1790763209442.8, now:406125.7000000477, elapsedMs:0,
  sameDocumentOrigin:true, visibility:'visible', hasFocus:true,
  viewportWidth:1024, viewportHeight:768, dpr:2,
  helperActiveCount:0, helperTracing:false, helperTraceCount:0, helperTraceCapacity:256,
  memorySupported:true, usedJSHeapSize:137061506, totalJSHeapSize:178525982,
  jsHeapSizeLimit:4395630592,
  memoryScope:'optional coarse Chrome JS; native/GPU/precision OPEN'
};
let checks = 0;
const equal = (actual, expected) => {assert.deepEqual(JSON.parse(JSON.stringify(actual)), expected); checks++;};
const rejects = (call, pattern) => {assert.throws(call, pattern); checks++;};
function fixture(overrides = {}) {
  return vm.createContext({
    performance:{now:()=>raw.now, timeOrigin:raw.timeOrigin, memory:{
      usedJSHeapSize:raw.usedJSHeapSize, totalJSHeapSize:raw.totalJSHeapSize, jsHeapSizeLimit:raw.jsHeapSizeLimit}},
    document:{visibilityState:'visible',hasFocus:()=>true},
    innerWidth:1024,innerHeight:768,devicePixelRatio:2,
    __cnMultiTouch:{state:()=>({activeCount:0,tracing:false,traceCount:0,traceCapacity:256})},
    ...overrides
  });
}
function evaluate(source, context, args = []) {
  const fn = new vm.Script(`(${source})`).runInContext(context, {timeout:1000});
  return fn(...args);
}
// Faithful bounded model of installed tools/script.js handler: UID resolution
// happens before function evaluation; McpPage requires an existing snapshot.
function throughUidBoundary(request, context, snapshot = null) {
  const args = (request.args || []).map(uid => {
    if (!snapshot) throw new Error('No snapshot found for page 9. Use take_snapshot to capture one.');
    if (!Object.hasOwn(snapshot, uid)) throw new Error(`Element uid "${uid}" not found on page 9.`);
    return snapshot[uid];
  });
  return evaluate(request.function, context, args);
}
const anchor = {timeOrigin:raw.timeOrigin,now:raw.now};
const oldCall = {function:'() => {throw new Error("function should not run");}',args:[String(raw.timeOrigin),String(raw.now)]};
rejects(()=>throughUidBoundary(oldCall,fixture()),/No snapshot found/);
rejects(()=>throughUidBoundary(oldCall,fixture(),{}),/Element uid/);
const baselineRequest = buildEvaluateRequest({pageId:9,filePath:'ROOT_SUPPORTED/baseline.json'});
equal(Object.hasOwn(baselineRequest,'args'),false);
equal(throughUidBoundary(baselineRequest,fixture()),raw);
const explicit = buildEvaluateRequest({pageId:9,filePath:'ROOT_SUPPORTED/sample.json',anchor});
equal(Object.hasOwn(explicit,'args'),false);
equal(explicit.waitForStableDom,false);
equal(throughUidBoundary(explicit,fixture()),raw);
const laterPerformance = {now:()=>raw.now+300000,timeOrigin:raw.timeOrigin,memory:{
  usedJSHeapSize:raw.usedJSHeapSize,totalJSHeapSize:raw.totalJSHeapSize,jsHeapSizeLimit:raw.jsHeapSizeLimit}};
equal(throughUidBoundary(explicit,fixture({performance:laterPerformance})),{
  ...raw,now:raw.now+300000,elapsedMs:300000});
equal(evaluate(buildSamplerFunction(),fixture({performance:laterPerformance})),{
  ...raw,now:raw.now+300000,elapsedMs:0});
const changed = throughUidBoundary(explicit,fixture({performance:{...laterPerformance,timeOrigin:raw.timeOrigin+1}}));
equal(changed.sameDocumentOrigin,false);
const missing = throughUidBoundary(explicit,fixture({performance:{now:()=>raw.now,timeOrigin:raw.timeOrigin}}));
equal([missing.memorySupported,missing.usedJSHeapSize,missing.totalJSHeapSize,missing.jsHeapSizeLimit],[false,null,null,null]);
const context = fixture();
const globals = Object.keys(context).sort();
throughUidBoundary(explicit,context);
equal(Object.keys(context).sort(),globals);
for (const bad of [NaN,Infinity,-Infinity,-1,'406125.7','1);globalThis.bad=1;//',null,undefined,true,{}]) {
  rejects(()=>buildSamplerFunction({timeOrigin:raw.timeOrigin,now:bad}),/finite nonnegative number/);
  rejects(()=>buildSamplerFunction({timeOrigin:bad,now:raw.now}),/finite nonnegative number/);
}
for (const bad of ['anchor',1,[],true]) rejects(()=>buildSamplerFunction(bad),/Anchor must/);
rejects(()=>buildEvaluateRequest({pageId:0,filePath:'x',anchor}),/Invalid pageId/);
rejects(()=>buildEvaluateRequest({pageId:NaN,filePath:'x',anchor}),/Invalid pageId/);
rejects(()=>buildEvaluateRequest({pageId:9,filePath:'',anchor}),/Missing external/);
console.log(`WEB RETENTION SAMPLER: PASS (${checks} offline checks; old scalar args fail UID boundary; no live tool/engine)`);
