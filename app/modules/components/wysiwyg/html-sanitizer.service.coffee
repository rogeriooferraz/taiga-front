###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

class HtmlSanitizerService
    sanitize: (html) ->
        return DOMPurify.sanitize(html || '', {
            ALLOWED_NAMESPACES: ['http://www.w3.org/1999/xhtml'],
            ALLOW_DATA_ATTR: false,
            ALLOW_ARIA_ATTR: false,
            ALLOWED_TAGS: [
                'a', 'abbr', 'b', 'blockquote', 'br', 'code', 'dd', 'del',
                'details', 'div', 'dl', 'dt', 'em', 'figcaption', 'figure',
                'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'input',
                'ins', 'kbd', 'label', 'li', 'ol', 'p', 'pre', 's', 'small',
                'span', 'strike', 'strong', 'sub', 'summary', 'sup',
                'table', 'tbody', 'td', 'th', 'thead', 'tr', 'u', 'ul'
            ],
            ALLOWED_ATTR: [
                'alt', 'checked', 'class', 'data-mention', 'disabled', 'href', 'id', 'lang',
                'rel', 'src', 'start', 'target', 'title', 'type'
            ]
        })

angular.module('taigaComponents')
    .service('tgHtmlSanitizer', HtmlSanitizerService)
