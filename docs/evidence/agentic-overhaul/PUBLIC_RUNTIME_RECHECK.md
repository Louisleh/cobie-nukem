# Public runtime recheck — 2026-07-13

Target: <https://www.louislehmann.fyi/games/cobie-nukem/>

## `0.6.0-alpha.5` production-navigation release

Observed identity after website deployment `f9065c4`:

- version `0.6.0-alpha.5`;
- runtime revision `4059174`;
- status `Production navigation alpha`.

The uncached public landing and `?touch=1` play route were exercised at a
1024×768 tablet viewport. The page first displayed `DOWNLOADING GAME — FIRST
LOAD MAY TAKE A MOMENT`, then replaced the loader with a full-viewport canvas
and reached the stamped title screen. No browser warning/error messages were
captured. The public PCK was downloaded independently: 11,489,896 bytes,
SHA-256 `0249b13ca7036cd73d546c5923a927ce5c528591902947b3218a6e7203e86ac2`,
exactly matching the packaged artifact.

This proves public artifact identity, loader honesty, tablet containment, and
startup. Physical iPad Safari multi-touch, audio unlock, thermal behavior,
human pathing feel, and a full human playthrough remain explicit gates.

## `0.6.0-alpha.4` retained route evidence

Observed identity:

- version `0.6.0-alpha.4`;
- runtime revision `67a0ee4`;
- status `Agentic production alpha`.

## Desktop route

The deployed cache-keyed Web artifact was exercised in the in-app Chromium browser at 1280×720:

1. landing page → Play now;
2. title readiness and keyboard activation;
3. main menu → New Game;
4. five-card mission selector with only Salmon Creek unlocked;
5. Salmon Creek start and opening enemies/HUD;
6. unattended live combat through player death;
7. `COBIE DOWN` overlay with Retry/Menu;
8. Retry restored the opening field at 100 health and the authored 100 armor retry protection.

The runtime emitted no Godot-authored warning/error messages during startup or the route. The automation host logged Chromium's generic `UnknownError: If you see this error we have a bug. Please report this bug to chromium.` twice; it was not accompanied by a Godot stack, failed transition, or visible runtime fault and is recorded as browser-host noise rather than silently discarded.

## Tablet/touch route

The same public URL was reloaded at a 1024×768 viewport with `?touch=1`:

- title and mission selector remained contained inside the letterboxed viewport;
- Salmon Creek started successfully;
- the left Move joystick and right Aim joystick rendered independently;
- Fire, Use, Jump, Reload, weapon previous/next, and Menu controls were visible and did not cover the objective, health, armor, or ammunition readouts;
- the on-screen tutorial read `LEFT: MOVE  RIGHT: AIM  FIRE TO FETCH`.

This is deployed-browser layout and route evidence. It does not claim physical iPad multi-touch, Safari audio unlock, thermal behavior, browser-chrome resizing, haptics, or human ergonomics.
