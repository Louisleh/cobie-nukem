/* Browser-only measurement. Inject before navigation; never ship in the game. */
(() => {
  const MAX_PHASES = 16, MAX_FRAMES = 4096, MAX_EVENTS = 256;
  let phases = [], active, observer;
  const ids = new WeakMap();
  let nextId = 1;
  const id = object => {
    if (!object || typeof object !== 'object') return null;
    if (!ids.has(object)) ids.set(object, nextId++);
    return ids.get(object);
  };
  function recordTask(entry) {
    const phase = [...phases].reverse().find(p => entry.startTime >= p.start);
    if (!phase) return;
    phase.taskCount++;
    phase.taskMax = Math.max(phase.taskMax, entry.duration);
    if (phase.tasks.length === MAX_EVENTS) phase.tasks.shift();
    phase.tasks.push({start: entry.startTime, duration: entry.duration});
  }
  function setPhase(label) {
    if (observer) observer.takeRecords().forEach(recordTask);
    const now = performance.now();
    if (active) active.end = now;
    active = {label: String(label).slice(0, 80), start: now, end: null,
      frames: [], frameCount: 0, frameMax: 0, over100: 0,
      tasks: [], taskCount: 0, taskMax: 0, gl: {}, slowGL: []};
    phases.push(active);
    if (phases.length > MAX_PHASES) phases.shift();
  }
  setPhase('loading-title');
  if (typeof PerformanceObserver !== 'undefined') {
    observer = new PerformanceObserver(list => list.getEntries().forEach(recordTask));
    observer.observe({type: 'longtask', buffered: true});
  }
  let last, lastPhase;
  function frame(now) {
    // Never charge a transition's preceding idle/loading gap to the next phase.
    if (last !== undefined && lastPhase === active) {
      const gap = now - last;
      active.frameCount++;
      active.frameMax = Math.max(active.frameMax, gap);
      active.over100 += Number(gap > 100);
      if (active.frames.length === MAX_FRAMES) active.frames.shift();
      active.frames.push(gap);
    }
    last = now; lastPhase = active;
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
  const wrapped = new Set();
  for (const Type of [globalThis.WebGLRenderingContext, globalThis.WebGL2RenderingContext]) {
    if (!Type) continue;
    for (const name of ['compileShader', 'linkProgram', 'getShaderParameter',
      'getProgramParameter', 'getUniformLocation', 'useProgram', 'drawArrays', 'drawElements']) {
      let owner = Type.prototype;
      while (owner && !Object.prototype.hasOwnProperty.call(owner, name)) owner = Object.getPrototypeOf(owner);
      if (!owner || wrapped.has(owner[name])) continue;
      const original = owner[name];
      const replacement = function (...args) {
        const start = performance.now();
        try { return Reflect.apply(original, this, args); }
        finally {
          const duration = performance.now() - start;
          const stats = active.gl[name] ||= {count: 0, total: 0, max: 0};
          stats.count++; stats.total += duration; stats.max = Math.max(stats.max, duration);
          if (duration >= 4) {
            if (active.slowGL.length === MAX_EVENTS) active.slowGL.shift();
            active.slowGL.push({api: name, start, duration, object: id(args[0]), parameter: typeof args[1] === 'number' ? args[1] : null});
          }
        }
      };
      Object.defineProperty(owner, name, {...Object.getOwnPropertyDescriptor(owner, name), value: replacement});
      wrapped.add(replacement);
    }
  }
  globalThis.__cobieWebEvidence = {
    setPhase,
    reset() { observer?.takeRecords(); phases = []; last = undefined; lastPhase = undefined; setPhase('menu-steady'); },
    snapshot() {
      observer?.takeRecords().forEach(recordTask);
      return {url: location.href, css: [innerWidth, innerHeight], dpr: devicePixelRatio,
        limits: {phases: MAX_PHASES, framesPerPhase: MAX_FRAMES, eventsPerPhase: MAX_EVENTS},
        phases: JSON.parse(JSON.stringify(phases)),
        caveats: ['WebGL wrapper overhead; use for attribution, not uninstrumented acceptance',
          'rAF is browser opportunity, not Godot/GPU frame duration',
          'frame quantiles cover retained rolling samples; counts/max cover entire phase',
          'localhost/cache/driver state must be recorded separately']};
    }
  };
})();
