// This source code is licensed under the terms of the
// GNU Affero General Public License found in the LICENSE file in
// the root directory of this source tree.

'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {checkCatalogs} = require('../check_locale_icu');

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'taiga-locale-icu-'));
try {
    const write = (code, text) => fs.writeFileSync(
        path.join(dir, `locale-${code}.json`), JSON.stringify({COUNT: text})
    );
    const source = '{total, plural, =1{one watcher} other{# watchers}}';
    write('en', source);
    write('fr', '{total, plural, =1{un} other{#');
    let result = checkCatalogs(dir, ['en', 'fr']);
    assert.strictEqual(result.errors.length, 1);
    assert.match(result.errors[0], /^fr COUNT:/);

    write('fr', '{total, plural, =1{un} other{# personnes}}');
    result = checkCatalogs(dir, ['en', 'fr']);
    assert.deepStrictEqual(result, {checked: 2, errors: []});
    console.log('PASS: ICU compiler test');
} finally {
    fs.rmSync(dir, {recursive: true, force: true});
}
