# Selectable locale consistency

Run `npm run check:locale-keys` before merging translation changes. CI runs the
same command and its unit tests. The checker requires every selectable locale
to have exactly the English leaf keys, nonblank string values, valid JSON with
no duplicate keys, and the same interpolation placeholders at each key.
Placeholder names and repetition matter; whitespace inside `{{ }}` does not.
A failure identifies the locale and affected key. There is no debt baseline.

`scripts/selectable-locale-codes.json` mirrors the backend's selectable
languages. Review that list when backend language support changes. Hungarian
and Indonesian catalogs are shipped by the frontend but are not currently
selectable, so they are outside this gate. The checker verifies structure and
interpolation compatibility; it cannot certify English wording, translated
meaning, HTML markup, or native language quality. Review those separately and
route non-English catalog changes through the project's translation process.
