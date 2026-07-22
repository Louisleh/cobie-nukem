# Vertical-slice design records

These short records are the durable contract map for autonomous and human work:

- `combat.md` — weapon lifecycle and terminal feedback.
- `input.md` — profile-aware gameplay intent and event-edge boundaries.
- `checkpoints.md` — mission bootstrap and restore-order invariants.
- `rain-city-route.md` — definitive Rain City topology, route-state, sightline, and human-review boundaries.
- `enemies-and-encounters.md` — pressure, persistence, and actor recovery.
- `performance-accessibility.md` — platform tiers and information-preserving assists.
- `agentic-toolchain.md` — privileged local tools, evidence loop, and export safety.

The active product source of truth is `docs/PRD.md`, especially §1.5. Dependency order is in `docs/IMPLEMENTATION_PLAN.md`; current packet state is in `docs/WORLD_CLASS_BUILDOUT_LOG.md`; release history is in `docs/PHASE_ROADMAP_PRD.md`. Changes to these contracts require tests and a short entry in `docs/DECISIONS.md`.
