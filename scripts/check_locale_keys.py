#!/usr/bin/env python3
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.

"""Check selectable translations against the English source catalog."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re


DEFAULT_LOCALES_DIR = Path(__file__).resolve().parents[1] / "app/locales/taiga"
DEFAULT_SOURCE_DIR = Path(__file__).resolve().parents[1] / "app"
PLACEHOLDER = re.compile(r"{{\s*([^{}]*?)\s*}}")
STATIC_KEY = re.compile(
    r'''(?<![A-Za-z0-9_])["']([A-Z][A-Z0-9_-]*(?:\.[A-Z][A-Z0-9_-]*)+)["']'''
)
ICU_ARGUMENT = re.compile(
    r"\{\s*([A-Za-z_][\w]*)\s*,\s*(plural|select|selectordinal)\s*,"
)
ICU_SELECTOR = re.compile(r"(?<!\w)(=\d+|other)\s*\{")


def reject_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_catalog(path):
    with path.open(encoding="utf-8") as source:
        catalog = json.load(source, object_pairs_hook=reject_duplicate_keys)
    if not isinstance(catalog, dict):
        raise ValueError("catalog root must be an object")
    return catalog


def flatten(catalog, prefix=""):
    if not catalog:
        raise ValueError(f"empty catalog object: {prefix or '<root>'}")
    result = {}
    for key, value in catalog.items():
        if not key or "." in key:
            raise ValueError(f"invalid catalog key: {key!r}")
        path = f"{prefix}.{key}" if prefix else key
        if isinstance(value, dict):
            result.update(flatten(value, path))
        elif isinstance(value, str):
            if not value.strip():
                raise ValueError(f"blank translation: {path}")
            result[path] = value
        else:
            raise ValueError(f"translation is not a string: {path}")
    return result


def placeholders(value):
    found = PLACEHOLDER.findall(value)
    if value.count("{{") != len(found) or any(not name.strip() for name in found):
        raise ValueError("malformed translation placeholder")
    depth = 0
    for character in PLACEHOLDER.sub("", value):
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
        if depth < 0:
            raise ValueError("unmatched translation brace")
    if depth:
        raise ValueError("unmatched translation brace")
    return Counter(name.strip() for name in found)


def icu_tokens(value):
    return (Counter(ICU_ARGUMENT.findall(value)),
            Counter(ICU_SELECTOR.findall(value)))


def validate_codes(locale_codes):
    if not isinstance(locale_codes, list) or "en" not in locale_codes:
        raise ValueError("supported locales must be a list including en")
    if len(locale_codes) != len(set(map(str, locale_codes))) or any(
        not isinstance(code, str) or not re.fullmatch(r"[a-z]+(?:-[a-z]+)*", code)
        for code in locale_codes
    ):
        raise ValueError("supported locale codes must be unique and valid")


def check_source_references(source_dir, english_keys):
    """Find literal catalog keys in CoffeeScript and Jade source files."""
    if not source_dir.is_dir():
        raise ValueError(f"source directory does not exist: {source_dir}")
    paths = sorted(path for path in source_dir.rglob("*")
                   if path.suffix in {".coffee", ".jade"})
    if not paths:
        raise ValueError(f"no CoffeeScript or Jade sources found: {source_dir}")
    missing = {}
    for path in paths:
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for key in STATIC_KEY.findall(line):
                # These are prefixes completed by a runtime suffix.
                if key.endswith("_") or key in english_keys:
                    continue
                missing.setdefault(key, []).append(f"{path}:{number}")
    return missing


def check_locales(locales_dir, locale_codes=None):
    english_path = locales_dir / "locale-en.json"
    english = flatten(load_catalog(english_path))
    for key, value in english.items():
        try:
            placeholders(value)
        except ValueError as error:
            raise ValueError(f"English {key}: {error}") from error

    if locale_codes is None:
        translations = sorted(
            path for path in locales_dir.glob("locale-*.json")
            if path != english_path
        )
    else:
        validate_codes(locale_codes)
        translations = [locales_dir / f"locale-{code}.json"
                        for code in locale_codes if code != "en"]
    if not translations:
        raise ValueError("no translated catalogs found")

    failures = {}
    for path in translations:
        try:
            actual = flatten(load_catalog(path))
            missing = sorted(english.keys() - actual.keys())
            extra = sorted(actual.keys() - english.keys())
            placeholder_errors = []
            icu_errors = []
            for key in sorted(actual.keys() & english.keys()):
                try:
                    expected_tokens = placeholders(english[key])
                    actual_tokens = placeholders(actual[key])
                    if actual_tokens != expected_tokens:
                        placeholder_errors.append(key)
                except ValueError:
                    placeholder_errors.append(key)
                if icu_tokens(english[key]) != icu_tokens(actual[key]):
                    icu_errors.append(key)
            if missing or extra or placeholder_errors or icu_errors:
                failures[path.name] = {
                    "missing": missing, "extra": extra,
                    "placeholders": placeholder_errors, "icu": icu_errors,
                    "errors": []
                }
        except (OSError, UnicodeError, ValueError) as error:
            failures[path.name] = {
                "missing": [], "extra": [], "placeholders": [], "icu": [],
                "errors": [str(error)]
            }
    return len(translations), failures


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locales-dir", type=Path, default=DEFAULT_LOCALES_DIR)
    parser.add_argument("--supported-codes-file", type=Path,
                        help="JSON list of selectable locale codes")
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE_DIR,
                        help="CoffeeScript and Jade sources to check against English")
    args = parser.parse_args()
    try:
        codes = None
        if args.supported_codes_file:
            with args.supported_codes_file.open(encoding="utf-8") as source:
                codes = json.load(source)
        count, failures = check_locales(args.locales_dir, codes)
        english_keys = flatten(load_catalog(args.locales_dir / "locale-en.json"))
        missing_references = check_source_references(args.source_dir, english_keys)
    except (OSError, UnicodeError, ValueError) as error:
        parser.exit(1, f"locale check failed: {error}\n")

    for name, details in failures.items():
        print(f"{name}: " + ", ".join(
            f"{len(paths)} {label}" for label, paths in details.items()
        ))
        for label, paths in details.items():
            for path in paths[:5]:
                print(f"  {label}: {path}")
            if len(paths) > 5:
                print(f"  {label}: ... and {len(paths) - 5} more")
    if failures:
        print(f"FAIL: {len(failures)}/{count} catalogs differ from English")
        return 1
    for key, locations in missing_references.items():
        print(f"Missing English source key {key}: {locations[0]}")
    if missing_references:
        print(f"FAIL: {len(missing_references)} source keys are absent from English")
        return 1
    print(f"PASS: {count} catalogs match English keys and format tokens")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
