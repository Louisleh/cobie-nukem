# RC3 cumulative feedback candidate — local preparation

Status: PUBLISHED WEB FEEDBACK RELEASE on October 3. The local-preparation receipt below is preserved; the subsequent owner-authorized publication is recorded in the final section. The optional ZIP download remains blocked by transport failures.

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


## October 3 publication outcome

New owner approval was accepted. Source branch `codex/rc3-feedback-publication` published the reviewed documentation head `c30a65f71bf6b61ded0e690838b6d168d6b8c365`; [source CI37141090567](https://github.com/Louisleh/cobie-nukem/actions/runs/37141090567) passed. [Release/tag v0.11.0-alpha.1-rc3](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.11.0-alpha.1-rc3) targets the exact frozen export source `07577cc22efed1475205f15bc232aa3217c5f58c`. Game main/PR75 integration remains separate.

[Site PR216](https://github.com/Louisleh/louislehmann-site/pull/216), head `d89062bc02915d1214ed95fc663eb581e47e56fe`, squash-merged as `60f47f81cbe0fe37303f912e504e19a2bf392734` at17:50:55UTC. PR CI37141722003, main CI37142018198 and Vercel production deployment6831031628 passed. The exact nine runtime files match the frozen package. Source/site artifact hashes and all previous rollback files remain preserved. HTTP/1.1 with a bounded request buffer resolved the site push TLS failure without persistent configuration changes.

[Live browser build](https://www.louislehmann.fyi/games/cobie-nukem/play/) verified at17:52:29UTC: downloaded PCK70,075,140 bytes, SHA256 `308a2e95470fe5b4271456dbc3cd9aefe11ef2957c3d5483fb5c24f8a92ad353`. Landing/play HTML are byte-identical to the merged candidate. Ordinary and cache-busted boot visibly identify RC3/cb52fce42ada. Live Chrome54.313s confirms primary15→13, secondary12, footer mouseStart15→13, pause/Main Menu/Doghouse with no console warning/error. A later Resume click in that first trace stayed paused; its labels are not accepted as actual states. One focused49.892s follow-up with explicit longer ordinary input waits confirms mouse Resume recaptures at13 rounds, next shot12 and actual Main Menu return, without keyboard fallback or console warning/error. No timing-robustness or human/device/full-route claim is added.

The release contains notes and hash/build metadata. The optional74,697,631-byte itch ZIP could not be attached after three HTTPS upload failures (TLS bad-record-MAC, reset, broken pipe); no partial asset remains. Public release notes disclose this remaining delivery gap. The frozen ZIP remains local at the previously recorded hash, and no alternate package was substituted. The playable Web deployment is complete. All owned jobs ended. Publication receipts and screenshot evidence are in `outputs/cobie-rc3-publication/`; prior native/performance/full-mission limitations remain unchanged.
