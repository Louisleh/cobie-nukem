# Combat contract

Every weapon follows `HOLSTERED → RAISING → READY → FIRING → RECOVERING →
RELOADING → LOWERING`. A request may queue one replacement weapon; duplicate
requests are idempotent. A shot resolves exactly once as miss, world,
destructible, or enemy and emits a `CombatFeedbackEvent` in the collision frame.

The event, not weapon-specific UI code, drives crosshair, impact, audio, target
reaction, and local playtest metrics. Surface identity comes from metadata or a
named group. Projectiles use physics movement with bounded bounces and per-target
repeat-hit suppression. Recoil presentation never changes the authoritative aim.
