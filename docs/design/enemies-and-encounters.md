# Enemy and encounter contract

Enemies expose `set_target`, `apply_damage`, `died`, health fraction, and stable
definition metadata. CombatPressure limits simultaneous attacks; state exit,
death, reset, pause, and scene removal must release tokens.

Checkpoint saves persist only completed encounter IDs. Live actors, timers, and
projectiles never serialize. An active encounter restarts from its authored wave
on retry. Spawn failure is named and cannot count as completion. Navigation
failure must recover or fail loudly; falling through terrain is never a death
presentation.
