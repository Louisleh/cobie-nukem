/* Exercise the actual shipping JavaScriptBridge expression against browser URL rules. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('scripts/ui/menu_controller.gd', 'utf8');
const match = source.match(/JavaScriptBridge\.eval\(("[^\n]+"), true\)/);
assert.ok(match, 'shipping menu navigation expression exists');
const script = JSON.parse(match[1]);
for (const [here, expected] of [
 ['http://127.0.0.1:8062/?touch=1', 'http://127.0.0.1:8062/'],
 ['https://example.com/play/', 'https://example.com/'],
 ['https://example.com/cobie/play/?touch=1#x', 'https://example.com/cobie/'],
 ['https://example.com/preview/', 'https://example.com/preview/'],
 ['https://example.com/cobie/play', 'https://example.com/cobie/'],
]) {
 for (const framed of [false, true]) {
  const window = {location:{href:here}};
  window.top = framed ? {location:{href:'https://example.com/host/'}} : window;
  vm.runInNewContext(script, {window, URL});
  assert.equal(window.top.location.href, expected);
  if (framed) assert.equal(window.location.href, here);
 }
}
console.log('PASS: shipping menu Return to Site URL across ten mount/frame cases');
