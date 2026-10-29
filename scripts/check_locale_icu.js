// This source code is licensed under the terms of the
// GNU Affero General Public License found in the LICENSE file in
// the root directory of this source tree.

'use strict';

const fs = require('fs');
const path = require('path');
const MessageFormat = require('messageformat');

const ICU_ARGUMENT = /\{\s*\w+\s*,\s*(plural|select|selectordinal)\s*,/;

function flatten(catalog, prefix = '', result = {}) {
    for (const [key, value] of Object.entries(catalog)) {
        const name = prefix ? `${prefix}.${key}` : key;
        if (typeof value === 'string') {
            result[name] = value;
        } else {
            flatten(value, name, result);
        }
    }
    return result;
}

function checkCatalogs(localesDir, codes) {
    const read = code => flatten(JSON.parse(fs.readFileSync(
        path.join(localesDir, `locale-${code}.json`), 'utf8'
    )));
    const english = read('en');
    const keys = Object.keys(english).filter(key => ICU_ARGUMENT.test(english[key]));
    const errors = [];
    let checked = 0;
    for (const code of codes) {
        const catalog = read(code);
        const formatter = new MessageFormat(code);
        for (const key of keys) {
            try {
                const render = formatter.compile(catalog[key]);
                for (const count of [0, 1, 2]) {
                    render({total: count, projects: count});
                }
                checked++;
            } catch (error) {
                errors.push(`${code} ${key}: ${error.message}`);
            }
        }
    }
    return {checked, errors};
}

if (require.main === module) {
    const root = path.resolve(__dirname, '..');
    const codes = JSON.parse(fs.readFileSync(
        path.join(__dirname, 'selectable-locale-codes.json'), 'utf8'
    ));
    const result = checkCatalogs(path.join(root, 'app/locales/taiga'), codes);
    for (const error of result.errors) console.error(error);
    if (result.errors.length) process.exitCode = 1;
    else console.log(`PASS: ${result.checked} ICU strings compile and render`);
}

module.exports = {checkCatalogs};
