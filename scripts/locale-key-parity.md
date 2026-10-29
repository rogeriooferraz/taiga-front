# Selectable locale consistency

Run `npm run check:locale-keys` and `npm run check:locale-format` before
merging translation changes. CI runs both commands and their unit tests. The
checker requires every selectable locale to have exactly the English leaf
keys, nonblank string values, valid JSON with
no duplicate keys, and the same interpolation placeholders and ICU plural
controls at each key. Placeholder names and repetition matter; whitespace
inside `{{ }}` does not. ICU variable names and selectors such as `=1` and
`other` must remain valid. The format check compiles and renders every ICU
message for zero, one, and two with the shipped MessageFormat library.
A source scan also checks literal dotted keys in CoffeeScript and Jade against
the English catalog. Keys assembled with runtime suffixes require separate
review.
A failure identifies the locale and affected key. There is no debt baseline.

`scripts/selectable-locale-codes.json` mirrors the backend's selectable
languages. Review that list when backend language support changes. Hungarian
and Indonesian catalogs are shipped by the frontend but are not currently
selectable, so they are outside this gate. The checker verifies structure and
interpolation compatibility; it cannot certify English wording, translated
meaning, HTML markup, or native language quality. Review those separately and
route non-English catalog changes through the project's translation process.
