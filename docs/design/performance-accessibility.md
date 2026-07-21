# Performance and accessibility contract

`QualityProfile` selects bounded Web/iPad or enhanced native budgets. Optimizing
requires before/after evidence; gameplay rules and progression remain identical.
Combat hot paths use reusable nodes: Fetch projectiles return to the existing
`ProjectilePool`, while one player-owned impact service preallocates at most 20 shared
impact roots plus reusable meshes, materials, and animation state across every weapon.
Pool tests inspect real instance IDs, prove the shared cap remains below the Web decal
budget of 32, verify complete teardown, and reject mutable Fetch state contamination
across reuse. Headless timing detects stalls only and is not rendered GPU evidence.

Resetting options emits every restored setting. Runtime listeners reapply audio, and
QualityManager responds only to `video/quality`, producing one immediate profile
apply without scene reload.

Accessibility controls preserve information: reduced motion removes camera
displacement but keeps hit direction and telegraphs; reduced flash substitutes
shape/contrast; captions represent important non-speech cues. Touch and desktop
share authoritative movement/combat while retaining separate response curves.
Physical iPad comfort, thermals, and photosensitivity remain human gates.

Touch gameplay uses fixed, visible twin sticks by default. Each stick exclusively
owns one finger until release: movement emits a normalized vector and aiming emits
a rate vector consumed in physics ticks. Action buttons own separate fingers.
Swipe velocity never controls aim and the aim stick never fires automatically.
Small/medium/large size and compact/standard/wide placement presets are the
supported 0.6 customization surface; freeform dragging remains deferred.
