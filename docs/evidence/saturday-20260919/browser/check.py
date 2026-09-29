from pathlib import Path
import json
from playwright.sync_api import sync_playwright

out=Path('/Users/orion/Desktop/Hermes Files/projects/cobie-nukem/docs/evidence/saturday-20260919/browser')
out.mkdir(parents=True,exist_ok=True)
logs=[]
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless=True)
    try:
        page=browser.new_page(viewport={'width':1280,'height':720})
        page.on('console',lambda msg:logs.append({'level':msg.type,'text':msg.text}))
        page.on('pageerror',lambda err:logs.append({'level':'pageerror','text':str(err)}))
        response=page.goto('http://127.0.0.1:8060/',timeout=30000)
        assert response.status==200
        page.wait_for_function("document.querySelector('canvas') && !document.getElementById('status')",timeout=45000)
        page.wait_for_timeout(5000)
        page.screenshot(path=str(out/'boot.png'))
        page.keyboard.press('Enter')
        page.wait_for_timeout(2500)
        page.screenshot(path=str(out/'after-enter.png'))
        page.keyboard.press('Enter')
        page.wait_for_timeout(1500)
        page.screenshot(path=str(out/'doghouse.png'))
        for _ in range(5): page.keyboard.press('Tab')
        page.keyboard.press('Enter')
        page.wait_for_timeout(3000)
        page.screenshot(path=str(out/'selector.png'))
        page.mouse.click(1185,698)
        page.wait_for_timeout(10000)
        page.screenshot(path=str(out/'level1-entry.png'))
        page.keyboard.down('w')
        page.wait_for_timeout(750)
        page.keyboard.up('w')
        page.screenshot(path=str(out/'level1-moved.png'))
        page.keyboard.press('Escape')
        page.wait_for_timeout(500)
        page.screenshot(path=str(out/'pause.png'))
        page.set_viewport_size({'width':1024,'height':768})
        page.wait_for_timeout(500)
        page.screenshot(path=str(out/'pause-4x3.png'))
        (out/'console.json').write_text(json.dumps(logs,indent=2)+'\n')
        print(json.dumps({'url':page.url,'title':page.title(),'console':logs,'canvas':page.locator('canvas').bounding_box()},indent=2))
    finally:
        browser.close()
