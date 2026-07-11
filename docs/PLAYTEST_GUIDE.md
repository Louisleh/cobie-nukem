# Family Playtest Guide

## Before sending the link

Package and verify the exact candidate:

```bash
QA_EXPORTS=1 bash tools/release_validate.sh
SKIP_VALIDATION=1 VERSION=0.2.0-rc1 bash tools/package_release.sh
python3 -m http.server 8060 --directory builds/pages
```

Open `http://127.0.0.1:8060`, record the revision shown on the landing page, and complete the release-audit items that your available hardware supports. Send testers the hosted HTTPS URL when possible. A local address only works on the developer’s machine.

## Suggested tester message

> Want to test my dog-powered retro FPS? Open the link on a laptop or desktop, click **Play in browser**, and use keyboard/mouse. Please try to finish the first map without me explaining it. At the end—or whenever you stop—open **Playtest Feedback**, copy the report, answer its three questions, and text everything back to me. Bugs and confusing moments are especially useful.

## What the tester should do

Ask the tester to explore naturally. Do not explain gates, secrets, weapons, the Fetch Collar, boss phases, or where to go unless they are completely stuck. That confusion is product evidence.

Core route:

1. Open the landing page and start the browser build.
2. Choose New Game and inspect the map selector.
3. Try one locked map, then start the playable Salmon Creek map.
4. Complete the level through the Golden Tennis Ball and victory summary.
5. Pause once, change one option, and resume.
6. Die or fall off the map at least once and retry.
7. Fire and reload every weapon; notice ammo, sounds, impacts, enemy HP, and footsteps.
8. At the end, use **Copy Playtest Report** and answer:
   - What was the most fun moment?
   - Where were you confused or stuck?
   - What is the first thing you would change?

## Observer notes

Record timestamps without coaching:

- time from landing page to moving in-game;
- time to first enemy defeated;
- places where the player stops for more than 15 seconds;
- missed prompts, unreadable HUD elements, and incorrect assumptions;
- weapon chosen most/least and why;
- reload surprises and empty-ammo confusion;
- every failed pickup or apparent collision issue;
- deaths, checkpoint recovery, final completion time;
- words the player uses to describe sound, movement, enemies, and boss pacing.

## Bug report minimum

Capture:

- copied playtest report or exact build revision;
- browser/OS and input method;
- current map/zone and last checkpoint;
- expected result and actual result;
- repeatability (once, sometimes, always);
- screenshot or short recording when useful;
- browser console errors if the tester knows how to retrieve them.

Do not request names, emails, analytics consent, account creation, or other personal data. The session code should remain anonymous.
