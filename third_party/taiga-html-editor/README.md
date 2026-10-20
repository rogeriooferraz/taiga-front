# Taiga CKEditor translations

These 62 browser translation files were generated from
[`taigaio/taiga-html-editor`](https://github.com/taigaio/taiga-html-editor)
commit `06d56bcbe646f0ffdafba7bb76f0a0b9a8691128`, the revision pinned in
the earlier frontend lockfile. The editor is CKEditor 5 version 23.1.0.
Its nested `packages/ckeditor5-build-classic/package-lock.json` has SHA-256
`b7311fcad96fb3c94638285e1e31542f7a796e45cb35334a0f4433e596ac6152`.

The files were produced by copying the pinned editor source outside
`node_modules`, running `npm ci --ignore-scripts --no-audit --no-fund` in its
`packages/ckeditor5-build-classic` directory, then running its `build` script
with `NODE_OPTIONS=--openssl-legacy-provider` under Node 24.22.0. The legacy
OpenSSL setting was used only for that one-time Webpack 4 build. Do not edit
the generated JavaScript by hand.

All 60 translation files in the published private Taiga 6.10.3 frontend
candidate match these files byte for byte. The pinned source also generates
`hi.js` and `tk.js`. The license notice from the pinned editor source is
retained in [LICENSE.taiga-html-editor.md](LICENSE.taiga-html-editor.md).

The separate checked-in `elements.js` editor bundle is unchanged. It needs
the source and browser security review in the workspace frontend plan.
