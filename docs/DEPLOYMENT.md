# Deployment

## Produce verified artifacts

Install Godot 4.7 stable plus matching export templates, then run from the repository root:

```bash
QA_EXPORTS=1 bash tools/release_validate.sh
SKIP_VALIDATION=1 VERSION=0.11.0-alpha.1-rc1 bash tools/package_release.sh
```

Outputs:

- `builds/web/` — raw Godot Web export.
- `builds/pages/` — static landing page at `/` and game at `/play/`.
- `builds/packages/cobie-nukem-0.11.0-alpha.1-rc1-itch.zip` — itch.io Web upload with `index.html` at ZIP root.
- `builds/packages/cobie-nukem-0.11.0-alpha.1-rc1-macos-unsigned.zip` — unsigned macOS build.
- `builds/packages/SHA256SUMS.txt` and `BUILD_INFO.txt` — distribution evidence.

Serve the staged site locally:

```bash
python3 -m http.server 8060 --directory builds/pages
```

Visit `http://127.0.0.1:8060/`; direct game URL is `http://127.0.0.1:8060/play/`. Do not open the HTML with `file://` because WebAssembly loading requires HTTP.

## GitHub Pages

The workflow at `.github/workflows/ci.yml` validates, exports, packages, and uploads artifacts on every pull request and `main` push. A successful `main` push deploys the exact `builds/pages` artifact tested by that run.

One-time repository setup:

1. Open **Settings → Pages**.
2. Set **Source** to **GitHub Actions**.
3. Ensure Actions are allowed to run official and `chickensoft-games/setup-godot` actions.
4. Push `main`, inspect the `Godot release gates` run, and open its `github-pages` environment URL.
5. Verify `/`, `/play/`, browser console, audio activation, and pointer lock.

The source remote is `https://github.com/Louisleh/cobie-nukem`. GitHub Pages remains an optional secondary artifact host; the family-playtest release is deployed from the separate owner-site repository to `https://www.louislehmann.fyi/games/cobie-nukem/`. Follow that repository's game-export path and verify the runtime build label after every copy.

## itch.io

1. Create or open the game project on itch.io.
2. Choose **HTML** as the project kind.
3. Upload only the versioned `*-itch.zip` from `builds/packages`.
4. Select **This file will be played in the browser**.
5. Enable fullscreen and choose a viewport suitable for 16:9 gameplay (1280×720 is the validation baseline).
6. Save as draft, open the itch preview, and test loading, audio activation, pointer lock, pause, death/retry, and one full route.
7. Compare the uploaded file’s local SHA-256 against `SHA256SUMS.txt` before publishing.

## macOS distribution

The produced ZIP is intentionally unsigned. For private playtests, disclose the Gatekeeper limitation. Public distribution needs Developer ID signing, hardened runtime review, notarization, and stapling performed with owner-controlled Apple credentials. Never commit certificates, passwords, profiles, API keys, or `export_credentials.cfg`.

## Hosting requirements

- HTTPS in production.
- `application/wasm` for `.wasm` and normal JavaScript MIME types.
- Byte-range requests and compression are recommended.
- Do not rewrite `/play/index.pck`, `.wasm`, `.js`, or worklet requests to the landing page.
- The current single-thread Web export does not require cross-origin isolation headers.

After any host/CDN change, clear cache or use a new asset revision, then repeat the Web manual matrix in `docs/RELEASE_AUDIT.md`.
