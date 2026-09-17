# Pika Coach Web

Web preview of the offline-first Pika Coach. It keeps the native iPhone app
separate and uses a single-threaded Pikafish WebAssembly build for Safari and
desktop browsers. The original Flutter app lives in `../app`.

## Run locally

From the repository root:

```sh
bash web/scripts/fetch_engine.sh
cd web
npm test
python3 -m http.server 4173
```

Visit `http://localhost:4173`. Opening `index.html` as a local file will not
load the WebAssembly worker. Web assets are pinned and hash checked during
download. For a networked device, use HTTPS hosting; the PWA service worker
requires HTTPS.

Features: legal moves (basic check safety, cannon screens, horse legs,
elephant river, palace), FEN, undo, best move, MultiPV, typed cp/mate score,
move review and safe replay of legal principal variation. Long-check and
repetition adjudication need more work; the browser preview should not be used
as a tournament referee. Pikafish may analyze more slowly on mobile.

The upstream WebAssembly engine and bundled network have a separate GPLv3
engine and NNUE usage license; see `vendor/README.md` and `../LICENSE`.
