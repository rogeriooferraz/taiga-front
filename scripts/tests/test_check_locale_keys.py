#!/usr/bin/env python3
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "check_locale_keys.py"
SPEC = importlib.util.spec_from_file_location("check_locale_keys", SCRIPT)
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


class CheckLocaleKeysTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.locales_dir = Path(temporary.name)
        self.write("en", {"MENU": {"TITLE": "Open {{name}}", "CLOSE": "Close"}})

    def write(self, locale, catalog):
        (self.locales_dir / f"locale-{locale}.json").write_text(
            json.dumps(catalog), encoding="utf-8"
        )

    def check(self, codes=None):
        return CHECKER.check_locales(self.locales_dir, codes)

    def test_matching_keys_and_placeholders_allow_translation(self):
        self.write("fr", {"MENU": {"TITLE": "Ouvrir {{ name }}", "CLOSE": "Fermer"}})
        self.assertEqual(self.check(["en", "fr"]), (1, {}))

    def test_missing_extra_and_changed_structure_are_reported(self):
        self.write("fr", {"MENU": {"TITLE": "Ouvrir {{name}}", "NEW": "Nouveau"}})
        self.write("de", {"MENU": "Menü"})
        count, failures = self.check()
        self.assertEqual(count, 2)
        self.assertEqual(failures["locale-fr.json"]["missing"], ["MENU.CLOSE"])
        self.assertEqual(failures["locale-fr.json"]["extra"], ["MENU.NEW"])
        self.assertEqual(failures["locale-de.json"]["extra"], ["MENU"])

    def test_duplicate_keys_in_english_or_translation_are_rejected(self):
        raw = '{"MENU": {"TITLE": "A", "TITLE": "B"}}'
        (self.locales_dir / "locale-en.json").write_text(raw, encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "duplicate JSON key"):
            self.check(["en", "fr"])
        self.write("en", {"MENU": {"TITLE": "Open {{name}}", "CLOSE": "Close"}})
        (self.locales_dir / "locale-fr.json").write_text(raw, encoding="utf-8")
        _, failures = self.check(["en", "fr"])
        self.assertIn("duplicate JSON key", failures["locale-fr.json"]["errors"][0])

    def test_blank_values_and_empty_objects_are_rejected(self):
        self.write("fr", {"MENU": {"TITLE": "  ", "CLOSE": "Fermer"}})
        _, failures = self.check(["en", "fr"])
        self.assertIn("blank translation", failures["locale-fr.json"]["errors"][0])
        self.write("fr", {"MENU": {}})
        _, failures = self.check(["en", "fr"])
        self.assertIn("empty catalog object", failures["locale-fr.json"]["errors"][0])
        self.write("en", {"MENU": {"TITLE": " ", "CLOSE": "Close"}})
        with self.assertRaisesRegex(ValueError, "blank translation"):
            self.check(["en", "fr"])

    def test_missing_extra_and_repeated_placeholders_are_reported(self):
        self.write("en", {"TITLE": "{{name}} and {{name}}", "ONCE": "{{::name}}"})
        self.write("fr", {"TITLE": "{{name}} and {{other}}", "ONCE": "{{name}}"})
        _, failures = self.check(["en", "fr"])
        self.assertEqual(failures["locale-fr.json"]["placeholders"],
                         ["ONCE", "TITLE"])
        self.write("fr", {"TITLE": "{{name}}", "ONCE": "{{::name}}"})
        _, failures = self.check(["en", "fr"])
        self.assertEqual(failures["locale-fr.json"]["placeholders"], ["TITLE"])

    def test_malformed_placeholder_is_reported(self):
        self.write("fr", {"MENU": {"TITLE": "Ouvrir {{name}", "CLOSE": "Fermer"}})
        _, failures = self.check(["en", "fr"])
        self.assertEqual(failures["locale-fr.json"]["placeholders"],
                         ["MENU.TITLE"])
        self.write("fr", {"MENU": {"TITLE": "Ouvrir {{name}} }}", "CLOSE": "Fermer"}})
        _, failures = self.check(["en", "fr"])
        self.assertEqual(failures["locale-fr.json"]["placeholders"],
                         ["MENU.TITLE"])

    def test_angular_and_icu_braces_can_coexist(self):
        source = "Hello {{name}}; {total, plural, =1{one} other{many}}"
        self.write("en", {"COUNT": source})
        self.write("fr", {"COUNT": "Bonjour {{name}}; {total, plural, =1{un} other{plusieurs}}"})
        self.assertEqual(self.check(["en", "fr"]), (1, {}))

    def test_unmatched_brace_without_angular_placeholder_is_reported(self):
        self.write("en", {"DATE": "DD MMM YYYY [at] hh:mm:ss"})
        self.write("fr", {"DATE": "DD MMM YYYY [à} hh:mm:ss"})
        _, failures = self.check(["en", "fr"])
        self.assertEqual(failures["locale-fr.json"]["placeholders"], ["DATE"])

    def test_icu_plural_braces_are_not_angular_placeholders(self):
        plural = "{total, plural, =1{one watcher} other{# watchers}}"
        self.write("en", {"COUNT": plural})
        self.write("fr", {"COUNT": "{total, plural, =1{un} other{# personnes}}"})
        self.assertEqual(self.check(["en", "fr"]), (1, {}))

    def test_icu_variable_and_selector_drift_are_reported(self):
        source = "{total, plural, =1{one watcher} other{# watchers}}"
        self.write("en", {"COUNT": source})
        self.write("fr", {"COUNT": "{somme, pluriel, =1{un} autres{#}}"})
        _, failures = self.check(["en", "fr"])
        self.assertEqual(failures["locale-fr.json"]["icu"], ["COUNT"])
        self.write("fr", {"COUNT": "{total, plural, 1{un} other{#}}"})
        _, failures = self.check(["en", "fr"])
        self.assertEqual(failures["locale-fr.json"]["icu"], ["COUNT"])
        self.write("fr", {"COUNT": "{total, plural, =1{un} other{#}}"})
        self.assertEqual(self.check(["en", "fr"]), (1, {}))

    def test_missing_supported_catalog_and_invalid_codes_are_rejected(self):
        self.write("fr", {"MENU": {"TITLE": "Ouvrir {{name}}", "CLOSE": "Fermer"}})
        self.write("id", {"MENU": {"TITLE": "extra only"}})
        self.assertEqual(self.check(["en", "fr"]), (1, {}))
        _, failures = self.check(["en", "fr", "de"])
        self.assertIn("No such file", failures["locale-de.json"]["errors"][0])
        for codes in (["en", "fr", "fr"], ["en", 3], ["fr"], ["en", "FR"]):
            with self.subTest(codes=codes):
                with self.assertRaises(ValueError):
                    self.check(codes)

    def test_non_string_translation_and_no_translations_are_rejected(self):
        self.write("fr", {"MENU": {"TITLE": None, "CLOSE": "Fermer"}})
        _, failures = self.check(["en", "fr"])
        self.assertIn("translation is not a string",
                      failures["locale-fr.json"]["errors"][0])
        (self.locales_dir / "locale-fr.json").unlink()
        with self.assertRaisesRegex(ValueError, "no translated catalogs"):
            self.check()

    def test_static_source_keys_must_exist_in_english(self):
        source_dir = self.locales_dir / "app"
        source_dir.mkdir()
        (source_dir / "view.jade").write_text(
            'p(translate="MENU.TITLE")\n'
            'p(title="{{ \'MENU.MISSING\' | translate }}")\n'
            'p(translate="MENU.DYNAMIC_{{suffix}}")\n',
            encoding="utf-8"
        )
        (source_dir / "controller.coffee").write_text(
            '$translate.instant("MENU.CLOSE")\n'
            '$translate.instant("MENU.ABSENT")\n',
            encoding="utf-8"
        )
        english = CHECKER.flatten(CHECKER.load_catalog(
            self.locales_dir / "locale-en.json"
        ))
        missing = CHECKER.check_source_references(source_dir, english)
        self.assertEqual(set(missing), {"MENU.MISSING", "MENU.ABSENT"})

    def test_missing_or_empty_source_tree_is_rejected(self):
        english = CHECKER.flatten(CHECKER.load_catalog(
            self.locales_dir / "locale-en.json"
        ))
        source_dir = self.locales_dir / "app"
        with self.assertRaisesRegex(ValueError, "does not exist"):
            CHECKER.check_source_references(source_dir, english)
        source_dir.mkdir()
        with self.assertRaisesRegex(ValueError, "no CoffeeScript or Jade"):
            CHECKER.check_source_references(source_dir, english)


if __name__ == "__main__":
    unittest.main()
