# OX-WCB-008L-M1A — Receipt verifier foundation

**Role:** bounded Ox Alpha writer, serialized milestone 1 of one logical lane
**Purpose:** implement and unit-test only the dependency-free receipt verifier for the future non-Movie-Maker 60-frame probe. Do not implement or launch Godot capture.

## Authority and baseline

Read `AGENTS.md`, `docs/OX_ALPHA_GAUNTLET.md`, `docs/work_packets/ox_alpha/wcb008l_m1s_frame_sequence_spike.md`, and the existing WCB-008L blocker/contract files they cite. The parent M1S packet remains the authority. This milestone narrows ownership; it does not weaken any acceptance or stop rule.

## Exact owned paths

- `tools/verify_wcb008l_frame_sequence_receipt.py`
- `tools/test_verify_wcb008l_frame_sequence_receipt.py`

No other path may change.

## Implementation requirements

Create a Python 3 standard-library verifier and standard-library unit tests. The verifier must accept explicit receipt, frame-directory, raw-log, expected-source-revision, expected-scene-hash, and expected-script-hash inputs. It must fail closed on at least:

- malformed/non-object JSON;
- wrong `mode`, eligibility, or canonical-duration labels;
- captured-frame count other than exactly 60;
- missing, extra, duplicate, or non-contiguous `000000.png`–`000059.png` frames;
- invalid PNG structure or dimensions inconsistent with the receipt;
- first/last frame SHA-256 mismatch;
- aggregate output-byte mismatch or ceiling above 64 MiB;
- source revision or scene/script SHA-256 mismatch;
- projected-render-frame telemetry represented as actual captured frames;
- completion reason other than the declared successful short-probe completion;
- raw logs containing parser/script errors, ObjectDB/resource leaks, `ParticlesShaderGLES3` not freed, shader/RID leaks, shader-cache creation failures, or any other engine `ERROR:` diagnostic.

The verifier must print one concise PASS sentinel only after every check succeeds and return nonzero otherwise. Tests must create real minimal valid PNG fixtures using only the standard library and cover a positive fixture plus negative fixtures for truncation, extra frame, relabeling, telemetry/count mismatch, tampered PNG/hash, source/hash drift, byte mismatch/ceiling, and forbidden diagnostics.

## Verification and commit

Run:

1. `python3 tools/test_verify_wcb008l_frame_sequence_receipt.py`
2. `python3 -m py_compile tools/verify_wcb008l_frame_sequence_receipt.py tools/test_verify_wcb008l_frame_sequence_receipt.py`
3. `git diff --check`
4. Exact owned-path check

Make one cohesive local commit only if all checks pass. Do not run Godot, edit the capture host/wrapper, push, merge, or claim rendered evidence. If the contract cannot be implemented within these two files, return blocked with a clean clone and explain the smallest missing contract.
