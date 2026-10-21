# Taiga CKEditor translations

These 63 browser translation files were generated from
[`taigaio/taiga-html-editor`](https://github.com/taigaio/taiga-html-editor)
commit `4f51e472fe45612530419fa0dfeb7fc700aabd2b`, the revision resolved by
the source build of Taiga's `elements.js` bundle. The editor is CKEditor 5
version 28.0.0.
Its nested `packages/ckeditor5-build-classic/package-lock.json` has SHA-256
`ea3feedcf9335942ed8237288d5ddc83b8efcb408b88cecff8cd44a45c6938cf`.

The files were produced by copying the pinned editor source outside
`node_modules`, running `npm ci --ignore-scripts --no-audit --no-fund` in its
`packages/ckeditor5-build-classic` directory, then running its `build` script
with `NODE_OPTIONS=--openssl-legacy-provider` under Node 22.12.0. The legacy
OpenSSL setting was used only for that one-time Webpack 4 build. Do not edit
the generated JavaScript by hand.

All 60 translation files checked into that editor source commit match the
rebuild byte for byte. The build additionally generates `hi.js`, `kk.js`, and
`tk.js`. This preserves the previous language set and adds Kazakh. The
license notice from the pinned editor source is retained in
[LICENSE.taiga-html-editor.md](LICENSE.taiga-html-editor.md).

The separate checked-in `elements.js` editor bundle is unchanged. These
translations match its CKEditor version; they do not establish that all editor
content paths are safe.
