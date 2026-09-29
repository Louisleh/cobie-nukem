#!/usr/bin/env node
// Bounded editor/runtime smoke test; this is NOT Cobie gameplay acceptance.
import { createRequire } from 'node:module';
import { writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
const [checkout, project, output] = process.argv.slice(2);
const require = createRequire(resolve(checkout, 'package.json'));
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');
const client = new Client({ name: 'cobie-env2-probe', version: '1.0.0' });
const transport = new StdioClientTransport({ command: process.execPath,
  args: [resolve(checkout, 'dist/index.js'), '--project', project], stderr: 'inherit' });
const steps = [];
async function call(name, args = {}) {
  const response = await client.callTool({ name, arguments: args }, undefined, { timeout: 15000 });
  const text = response.content?.find(item => item.type === 'text')?.text;
  if (response.isError || text === undefined) throw new Error(`${name}: ${text}`);
  let result; try { result = JSON.parse(text); } catch { result = text; }
  if (result?.error) throw new Error(`${name}: ${result.error}`);
  steps.push({ name, args, result });
  return result;
}
try {
  await client.connect(transport);
  const tools = await client.listTools();
  await call('godot_connect', { host: '127.0.0.1', port: 6550 });
  const identity = await call('godot_editor_get_project_info');
  if (!JSON.stringify(identity).includes('Cobie ENV2 Probe')) throw new Error('Wrong editor project');
  await call('godot_editor_get_scene_tree');
  await call('godot_editor_run_scene', { scenePath: 'res://probe.tscn' });
  // The editor may report running before the debugger harness can receive input.
  let harnessReady = false;
  for (let attempt = 0; attempt < 60; attempt++) {
    const log = await call('godot_editor_get_output', { lines: 100 });
    if (JSON.stringify(log).includes('Automation harness ready')) { harnessReady = true; break; }
    await new Promise(r => setTimeout(r, 200));
  }
  if (!harnessReady) throw new Error('Runtime debugger harness did not announce readiness');
  let ready = false;
  for (let attempt = 0; attempt < 30; attempt++) {
    await new Promise(r => setTimeout(r, 150));
    const status = await call('godot_runtime_status');
    if (status.scene_path === 'res://probe.tscn') { ready = true; break; }
  }
  if (!ready) throw new Error('Runtime did not become ready');
  await call('godot_runtime_tap_action', { action: 'ui_accept', frames: 2 });
  await call('godot_runtime_wait', { frames: 5 });
  const nodes = await call('godot_runtime_inspect_nodes', {
    group: 'probe', properties: ['taps'], maxResults: 1 });
  if (!nodes.count || nodes.nodes[0]?.properties?.taps !== 1) {
    throw new Error(`Input assertion failed: ${JSON.stringify(nodes)}`);
  }
  await call('godot_runtime_capture_screenshot', { path: resolve(output, 'probe.png') });
  const errors = await call('godot_editor_get_errors', {
    severity: 'error', includeRuntime: true, includeScript: true,
    includeLogFile: true, logLines: 300 });
  if (errors.count > 0) throw new Error(`Editor errors: ${JSON.stringify(errors)}`);
  await call('godot_editor_stop_scene');
  await call('godot_disconnect');
  await writeFile(resolve(output, 'mcp-result.json'), JSON.stringify({
    evidence_class: 'synthetic editor/runtime probe; not gameplay or device acceptance',
    tool_count: tools.tools.length, steps }, null, 2));
  console.log('PASS: Godot MCP editor/runtime/input/capture smoke');
} catch (error) {
  await writeFile(resolve(output, 'mcp-result.json'), JSON.stringify({ steps, error: String(error) }, null, 2));
  throw error;
} finally { await client.close(); }
