###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

describe 'tgHtmlSanitizer', ->
    sanitizer = null

    beforeEach ->
        module 'taigaComponents'
        inject (_tgHtmlSanitizer_) ->
            sanitizer = _tgHtmlSanitizer_

    it 'keeps useful Markdown formatting, links, images and checkboxes', ->
        html = sanitizer.sanitize '<h2>Heading</h2><pre><code class="language-python">x</code></pre>' +
            '<a href="https://example.org/a" title="link">link</a>' +
            '<a class="mention" data-mention="true" href="project/demo">@demo</a>' +
            '<img src="/media/1" alt="file"><input type="checkbox" checked disabled>'
        result = document.createElement('template')
        result.innerHTML = html

        expect(result.content.querySelector('h2').textContent).to.equal 'Heading'
        expect(result.content.querySelector('code').className).to.equal 'language-python'
        expect(result.content.querySelector('a').getAttribute('href')).to.equal 'https://example.org/a'
        expect(result.content.querySelector('.mention').getAttribute('data-mention')).to.equal 'true'
        expect(result.content.querySelector('img').getAttribute('src')).to.equal '/media/1'
        expect(result.content.querySelector('input').checked).to.be.true

    it 'removes active content, executable URLs, and inline styling', ->
        html = sanitizer.sanitize '<script>window.pwned=1</script>' +
            '<svg onload="window.pwned=1"><a href="javascript:alert(1)">x</a></svg>' +
            '<a href="javascript:alert(1)" onclick="alert(1)" data-surprise="x" style="color:red">bad</a>' +
            '<img src="javascript:alert(1)" onerror="alert(1)">'
        result = document.createElement('template')
        result.innerHTML = html

        expect(result.content.querySelector('script, svg, [onclick], [onerror], [style], [data-surprise]')).to.be.null
        expect(result.content.querySelector('a').hasAttribute('href')).to.be.false
        expect(result.content.querySelector('img').hasAttribute('src')).to.be.false

describe 'tgWysiwygService HTML boundary', ->
    service = originalConverter = null
    converter = null

    beforeEach ->
        originalConverter = window.angularDataConversion
        converter = {
            setUp: sinon.stub(),
            toHtml: sinon.stub(),
            toMarkdown: sinon.stub(),
            originalRemoteImageUrl: sinon.stub().returns(null),
            deferRemoteImageUrl: sinon.stub().returnsArg(0)
        }
        window.angularDataConversion = -> converter

        module 'taigaComponents'
        module ($provide) ->
            $provide.value 'tgProjectService', {project: {get: (key) -> if key == 'id' then 1 else 'demo'}}
            $provide.value 'tgAttachmentsFullService', {attachments: {toJS: -> []}}
            $provide.value 'tgAttachmentsService', {
                get: -> Promise.resolve({data: {url: '/media/attachment.png'}})
            }
            return null
        inject (_tgWysiwygService_) ->
            service = _tgWysiwygService_

    afterEach ->
        window.angularDataConversion = originalConverter

    it 'sanitizes the converter output before other views receive it', ->
        converter.toHtml.returns '<p>Safe <strong>text</strong></p><img src=x onerror=alert(1)>'
        html = service.getHTML('**text**')

        expect(html).to.contain '<strong>text</strong>'
        expect(html).not.to.contain 'onerror'

    it 'sanitizes attachment URLs after they are resolved', ->
        service.getAttachmentData = -> Promise.resolve('javascript:alert(1)')
        service.refreshAttachmentURL('<img src="/media/#_taiga-refresh=task:1">').then (html) ->
            expect(html).not.to.contain 'javascript:'
            expect(html).not.to.contain 'src='

    it 'keeps safe resolved attachment URLs', ->
        service.refreshAttachmentURL('<img src="/media/#_taiga-refresh=task:1">').then (html) ->
            expect(html).to.contain 'src="/media/attachment.png"'

    it 'refreshes deferred cross-origin attachment images', ->
        deferred = 'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%2F%3E#taiga-remote-image=old'
        refreshed = 'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%2F%3E#taiga-remote-image=new'
        converter.originalRemoteImageUrl.withArgs(deferred).returns(
            'https://media.example/old.png#_taiga-refresh=task:1')
        converter.deferRemoteImageUrl.withArgs('https://media.example/new.png').returns(refreshed)
        service.getAttachmentData = -> Promise.resolve('https://media.example/new.png')

        service.refreshAttachmentURL('<img src="' + deferred + '">').then (html) ->
            expect(html).to.contain('src="' + refreshed + '"')
            expect(converter.deferRemoteImageUrl).to.have.been.calledWith(
                'https://media.example/new.png')

    it 'preserves email links while resolving relative project links', ->
        html = service.relativePaths '<a href="mailto:team@example.org">mail</a>' +
            '<a href="story/1">story</a>'

        expect(html).to.contain 'href="mailto:team@example.org"'
        expect(html).to.contain 'href="' + window.location.href.slice(0, window.location.href.lastIndexOf('/') + 1) + 'story/1"'
