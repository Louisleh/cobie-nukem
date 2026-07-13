# Enemy and encounter contract

Enemies expose `set_target`, `apply_damage`, `died`, health fraction, and stable
definition metadata. CombatPressure limits simultaneous attacks; state exit,
death, reset, pause, and scene removal must release tokens.

Checkpoint saves persist only completed encounter IDs. Live actors, timers, and
projectiles never serialize. An active encounter restarts from its authored wave
on retry. Spawn failure is named and cannot count as completion. Navigation
failure must recover or fail loudly; falling through terrain is never a death
presentation.

Ground enemies use `EnemyNavigator`, which throttles moving-target path updates,
keeps gravity in the actor physics tick, and requests recovery only after three
failed repaths. Recovery is clamped to a valid navigation point within three
metres, resets physics interpolation, increments local-only diagnostics, and
never applies to flying actors. Salmon Creek bakes once from temporary CPU-side
collision sources and removes those sources after forcing the initial map sync;
no runtime rebake or per-frame map force-update is permitted.
