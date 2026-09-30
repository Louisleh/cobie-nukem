// Contract regressions for idle saturation, transition charging and bounded storage.
const fs = require('fs'), vm = require('vm'), assert = require('node:assert/strict');
let now = 0, callback, taskCallback, pending = [];
class GL {
  getProgramParameter(program, parameter) { now += 7; return parameter; }
  compileShader() { throw new Error('original failure'); }
}
const context = {performance: {now: () => now},
  requestAnimationFrame: fn => {callback = fn;}, WebGLRenderingContext: GL,
  location: {href: 'http://localhost/probe'}, innerWidth: 1024, innerHeight: 768, devicePixelRatio: 2,
  PerformanceObserver: class {constructor(fn) {taskCallback = fn;} observe() {} takeRecords() {const out = pending; pending = []; return out;}}};
vm.createContext(context);
vm.runInContext(fs.readFileSync(__dirname + '/web_evidence_probe.js', 'utf8'), context);
const probe = context.__cobieWebEvidence;
function tick(gap) {now += gap; callback(now);}
for (let i = 0; i < 10000; i++) tick(16);
assert.equal(probe.snapshot().phases[0].frames.length, 4096);
pending.push({startTime: now - 50, duration: 60});
probe.setPhase('live');
tick(2000); // Old-phase loading must not pollute the live phase.
for (let i = 0; i < 30; i++) tick(33);
const gl = new GL(), program = {};
assert.equal(gl.getProgramParameter(program, 42), 42);
assert.throws(() => gl.compileShader({}), /original failure/);
let result = probe.snapshot();
assert.equal(result.phases[0].taskCount, 1);
assert.equal(result.phases[1].frameCount, 30);
assert.equal(result.phases[1].over100, 0);
assert.equal(result.phases[1].gl.getProgramParameter.max, 7);
assert.equal(result.phases[1].slowGL[0].parameter, 42);
for (let i = 0; i < 400; i++) taskCallback({getEntries: () => [{startTime: now, duration: 70}]});
assert.equal(probe.snapshot().phases[1].tasks.length, 256);
for (let i = 0; i < 30; i++) probe.setPhase('cycle-' + i);
assert.equal(probe.snapshot().phases.length, 16);
probe.reset();
result = probe.snapshot();
assert.equal(result.phases.length, 1);
assert.equal(result.phases[0].tasks.length, 0);
assert.equal(result.phases[0].frames.length, 0);
console.log('WEB EVIDENCE PROBE: PASS');
