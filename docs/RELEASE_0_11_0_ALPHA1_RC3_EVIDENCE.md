# RC3 cumulative feedback candidate — local preparation

Status: LOCAL ONLY, release preparation verified. No remote tag, release, PR, merge or deployment was performed or authorized by this preparation. Direct destination approval remains pending.

Version: `0.11.0-alpha.1-rc3`. Build ID: `2026-10-03-feedback-rc3`. Gameplay revision: `cb52fce42ada92336b1fbba8dd10a033ba446dac`; cumulative reviewed baseline: `a8e1a321c97c5924faa157421c9c046d00888e44`.

Current live RC2 remains `fe2b1bed1d925734a501644e02fc5fea4657375f`, with b0 gameplay, site merge `74afe9ba5c5b9eeaec24ba1c87afeae24cf7f89d` and PCK SHA256 `5077f60dc3ffb459616628af31f57f3a34e97633259153009110773bd09e6387`. Existing RC1 and all local RC2/HUD artifacts are preserved.

The exact stamped source/export commit is `07577cc22efed1475205f15bc232aa3217c5f58c`, branch `codex/cobie-feedback-rc3-20261003`. A later documentation-only closeout commit records this evidence without changing or rebuilding the frozen exports. Native packages are unsigned local validation outputs; ordinary native Quit and human/device/full-mission gates are not promoted.

Native Info.plist uses short version `0.11.0` and numeric build `11.1.3`; the full RC3 identity remains in BuildInfo. The preliminary metadata attempt and its successful functional matrix are preserved separately and not accepted as release output. Browser first-entry/first-fire stalls remain unresolved.

## Changes included

All reviewed repairs through `a8e1a321` are ancestors: encounter retry/death generation guards, Slice/Terminal spawn clearance, camera-facing enemy health fill, Rain City hold boundaries, centered reticle, native menu audio shutdown handling, and Enforcer difficulty initialization. `cb52fce42ada` additionally makes four display-only HUD controls ignore mouse input, with an actual viewport-to-production-weapon regression test. RC3 adds identity and native bundle metadata only; no gameplay breadth is added.

## Verification

| Check | Result |
| --- | --- |
| `QA_EXPORTS=1 bash tools/release_validate.sh` | Exit 0 in 161.745 seconds; import plus 66 Godot entrypoints (65 tests and content validation), fresh Web/macOS exports and both PCK checks |
| Diagnostics | 13 deliberate negative-fixture warnings; no engine/script errors, leaks or orphan diagnostics in the full matrix |
| Auxiliary CI tests | All five commands pass: three Node web-tool regression suites and Python workstation-doctor/Godot-MCP unit suites |
| Packaging | Exit 0; default version derives from BuildInfo; conflicting RC2 override rejects before packaging; ZIP integrity and SHA256SUMS pass |
| Embedded export identity | Both exact exported packs load RC3/cb52fce42ada/2026-10-03-feedback-rc3 and all four HUD mouse-filter properties; native plist confirms 0.11.0 / 11.1.3 |
| Packaged Chrome 154.0.8037.93 | Fresh foreground 1280×720 context, 51.673 seconds, 21 screenshots, zero console warnings/errors; title stamp visibly confirmed |
| Ordinary browser inputs | Rain City/Best Friend: captured portrait coordinate 166,536 fires primary 15→14→13 and secondary →12; mouse Start 1188,698 preserves 15 then fires to 13; pause releases capture, Resume preserves 13, next shot reaches 12; Main Menu/Doghouse respond |
| Browser evidence boundary | Trusted browser inputs and public DOM observation; no internal game-state query, pointer API override or injected gameplay; minimal pointer-lock control passes before/after |
| Preservation | RC1 rollback, frozen local reviewed RC2 and HUD diagnostic PCK hashes are unchanged; preliminary metadata exports and failed probe receipt retained |

Full matrix log SHA256: `af5ee76625f67f074e27e49ff1d00a7d44a455e3c36232cc55d3cd65f4fb2aa3`.

Evidence directory: `outputs/cobie-feedback-rc3/` in the Mac mini task workspace. See `release-qa-summary.json`, `auxiliary-checks.json`, `export-identity.json`, `pack-verification/final-results.json`, `browser-summary.json`, `browser-rc3-01/receipt.json`, and `preservation-check.json`. The first pack-inspection fixture did not match scene-state paths and encountered a sandbox CA diagnostic; its receipt is preserved. Corrected instance inspection passes cleanly on both unchanged packs. The preliminary semantic native build number was corrected before the final complete matrix/export.

## Frozen artifacts

| Artifact | Bytes | SHA256 |
| --- | ---: | --- |
| Web PCK, raw/Pages/itch identical | 70,075,140 | `308a2e95470fe5b4271456dbc3cd9aefe11ef2957c3d5483fb5c24f8a92ad353` |
| itch ZIP | 74,697,631 | `77a2e275afb936b0ed04b8a233cc1d82cc78ce848736dea3d849306dfa30a93a` |
| Unsigned macOS ZIP | 116,047,963 | `8f0574ae70f253f15b98334482b8760e0644d0bca1fec79a0b5d2dca5733d9b1` |

Packages are under `builds/packages/`; browser assets under `builds/pages/`. Runtime assets use `index-0.11.0-alpha.1-rc3.*`; executable/file-size metadata matches. Three generated PNG `.import` sidecars remain preserved in raw/Pages output and are excluded from the itch ZIP. Copy only the nine runtime play assets in a future website handoff.

## Publication resumption checklist

1. Obtain the direct destination authorization required by automatic approval review for the existing public game and website repositories. Do not retry through another transport or infer authorization from the external RC2 publication.
2. Re-read remote versions, source refs, website main and live PCK. RC3 was available at the local version check, but no remote reservation exists. Do not overwrite RC2 tags/assets; if a new collision exists, resolve identity and repeat affected verification.
3. Integrate the exact reviewed candidate through the existing source/release workflow and required CI. PR75 remains draft at b0; no main merge or native acceptance is implied by this local preparation. Bind the final release/tag to the reviewed source and record any integration commit separately.
4. Reconcile site PR215/current main, preserve unrelated work, and stage only the tested versioned RC3 runtime assets in `games/cobie-nukem`. Update the site-owned landing identity and disclosed limits; run `node scripts/build-site.mjs`, route verification and repository hygiene. Use the existing Vercel deployment workflow only.
5. After approved publication, download the public PCK and require the exact RC3 SHA256 above. Verify ordinary and cache-busted browser identity, boot, firing and menu recovery. Record source/tag, site commit, deployment and live artifact chain.
6. Preserve the currently published RC2 site commit `74afe9ba5c5b9eeaec24ba1c87afeae24cf7f89d` / PCK `5077f60dc3ffb459616628af31f57f3a34e97633259153009110773bd09e6387` for rollback, plus the older RC1/local evidence. No deletion, new host, signing, spending or security changes are part of this packet.

Remaining limitations: unresolved first-entry/first-fire stalls, ordinary native Quit/C5 history, complete Terminal/full-mission routes, strict retention/continuous opening evidence, human readability/feel and physical target-device acceptance. Readiness scores remain unchanged. Native-only observation was waived as a Web feedback release gate, not recorded as a pass. Optional Blender MCP remains absent and authentication configuration was deliberately not inspected; complete optional workstation health is not claimed.
