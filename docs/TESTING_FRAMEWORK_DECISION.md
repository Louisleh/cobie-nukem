# Testing-framework decision

GdUnit4 commit `237b1b19c2041790b277d6dbae10b402ffb9cb69` passed a bounded four-case Godot 4.7 pilot covering parameterized weapon data and async signal observation with no failures, flakes, skips, errors, or orphans.

Decision: **do not vendor now**. It adds roughly 459 globally scanned classes; its stock macOS runner requests invalid remote-debug port `0` under Godot 4.7; alternate closed ports emit expected connection noise; and headless UI `InputEvent` injection is explicitly ineffective. The current dependency-free scripts are deterministic, fast, Web-safe, and already express the release-critical behavior.

Reconsider only when a confirmed production defect needs scene-runner isolation, mocking, parameterized fuzz reporting, or richer CI reports that the current harness cannot express cleanly. Any adoption must coexist with—not replace—the current suite and remain excluded from exports.
