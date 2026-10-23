###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

class WysiwygService
    @.$inject = [
        "tgProjectService",
        "tgAttachmentsService",
        "tgHtmlSanitizer"
    ]

    constructor: (@projectService, @attachmentsService, @htmlSanitizer) ->
        @.projectDataConversion = {}
        # Coalesce concurrent reads without retaining signed URLs after they resolve.
        @.pendingAttachmentURLs = {}

    getMarkdown: (html) ->
        projectId = @projectService.project.get('id')

        if !@.projectDataConversion[projectId]
            @.dataConversion = window.angularDataConversion()
            @.dataConversion.setUp(@projectService.project.get('slug'))
            @.projectDataConversion[projectId] = @.dataConversion

        return @.projectDataConversion[projectId].toMarkdown(html)

    getHTML: (text) ->
        return "" if !text || !text.length

        projectId = @projectService.project.get('id')

        if !@.projectDataConversion[projectId]
            @.dataConversion = window.angularDataConversion()
            @.dataConversion.setUp(@projectService.project.get('slug'))
            @.projectDataConversion[projectId] = @.dataConversion

        return @htmlSanitizer.sanitize(@.projectDataConversion[projectId].toHtml(text))

    originalRemoteImageUrl: (src) ->
        return window.angularDataConversion().originalRemoteImageUrl(src)

    deferRemoteImageUrl: (src) ->
        return window.angularDataConversion().deferRemoteImageUrl(src)

    getAttachmentData: (tokens) ->
        return @attachmentsService.get(tokens[0], tokens[1]).then (response) => response.data.url

    getAttachmentURL: (tokens) ->
        key = "#{tokens[0]}:#{tokens[1]}"
        return @.pendingAttachmentURLs[key] if @.pendingAttachmentURLs[key]

        request = @.getAttachmentData(tokens)
        @.pendingAttachmentURLs[key] = request
        clear = => delete @.pendingAttachmentURLs[key]
        request.then(clear, clear)
        return request

    relativePaths: (html) ->
        el = document.createElement('template')
        el.innerHTML = @htmlSanitizer.sanitize(html)

        el.content.querySelectorAll('a').forEach (link) =>
            href = link.getAttribute('href')

            if href && !/^[a-z][a-z0-9+.-]*:/i.test(href) && !href.startsWith('/') && !link.classList.contains('mention')
                currentHref = window.location.href.slice(
                    0,
                    window.location.href.lastIndexOf('/') + 1
                );

                if !currentHref.endsWith('/')
                    currentHref = currentHref + '/'

                newHref = currentHref + link.getAttribute('href')
                link.removeAttribute('rel')
                link.removeAttribute('target')

                link.setAttribute('href', newHref)

            if href && href.startsWith('project') && link.classList.contains('mention')
                link.removeAttribute('rel')
                link.removeAttribute('target')

        return @htmlSanitizer.sanitize(el.innerHTML)

    refreshAttachmentURLFromMarkdown: (markdown) ->
        html = @.getHTML(markdown)

        return @.refreshAttachmentURL(html).then (html) =>
            return @.getMarkdown(html)

    refreshAttachmentURL: (html) ->
        el = document.createElement('template')
        el.innerHTML = @htmlSanitizer.sanitize(html)
        regex = /#_taiga-refresh=([a-zA-Z]*\:\d+)/

        links = {
            "elements": el.content.querySelectorAll('a'),
            "attr": "href",
        }
        images = {
            "elements": el.content.querySelectorAll('img'),
            "attr": "src",
        }

        promises = []
        _.map [links, images], (tag) =>
            _.map tag.elements, (e) =>
                attrValue = e.getAttribute(tag.attr)
                original = if tag.attr == 'src' then @.originalRemoteImageUrl(attrValue) else null
                refreshValue = original or attrValue

                if refreshValue && refreshValue.indexOf && refreshValue.indexOf('#_taiga-refresh=') != -1
                    match = refreshValue.match(regex)
                    if match && match.length == 2
                        tokens = match[1].split(":")

                        promise = @.getAttachmentURL(tokens)
                        .then (url) =>
                            resolved = if tag.attr == 'src' then @.deferRemoteImageUrl(url) else url
                            e.setAttribute(tag.attr, resolved)
                        .catch () =>
                            console.warn('attachment ref not found', attrValue)

                        promises.push(promise)

        Promise.all(promises).then =>
            return @htmlSanitizer.sanitize(el.innerHTML)

angular.module("taigaComponents")
    .service("tgWysiwygService", WysiwygService)
