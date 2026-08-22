# OX-WCB-008L-REOPEN-AUDIT

Perform a read-only, adversarial engineering audit of the stopped WCB-008L M1R evidence packet.

Read at minimum:

- `AGENTS.md`
- `.agents/skills/cobie-spark-orchestration/SKILL.md`
- `.agents/skills/cobie-godot-production/SKILL.md`
- `docs/PRD.md` §1.5
- `docs/IMPLEMENTATION_PLAN.md`, especially WCB-008L
- `docs/WORLD_CLASS_BUILDOUT_LOG.md` current state and WCB-008L entries
- `docs/work_packets/wcb008l/PRODUCTION_GAUNTLET.md`
- `docs/work_packets/wcb008l/M1R_CAPTURE_BLOCKER.md`
- existing capture scripts, tests, and visual-quality tooling relevant to a non-Movie-Maker external capture path

Question:

Can WCB-008L be truthfully reopened with a materially different, bounded external window-capture strategy that avoids Godot Movie Maker teardown while still proving an exact input-driven 90.0-second run, 2,700 rendered frames, 5,400 physics ticks, source/script hashes, fixed seed and quality, isolated user data, watchdogs, process/disk cleanup, and fail-closed receipts?

Deliver:

1. A concrete root-cause restatement that distinguishes application cleanup from evidence validity.
2. An inventory of reusable existing code and exact missing seams.
3. At most two candidate strategies, ranked by feasibility and evidence integrity.
4. The smallest dependency-safe spike, with exact proposed owned paths, frozen paths, acceptance checks, negative tests, resource bounds, and stop rules.
5. A verdict: `accept` only if the spike is materially different and does not relabel wall-clock video or staged screenshots as deterministic frame evidence; otherwise `blocked`.
6. No implementation, no file changes, no Godot run, and no human-quality claim.
