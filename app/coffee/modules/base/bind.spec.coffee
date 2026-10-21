###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
###

describe "HTML binding directives", ->
    $compile = null
    $rootScope = null

    beforeEach ->
        module "taigaBase", "ngSanitize"
        inject (_$compile_, _$rootScope_) ->
            $compile = _$compile_
            $rootScope = _$rootScope_

    it "sanitizes stored history HTML while retaining diff markup", ->
        scope = $rootScope.$new()
        scope.html = '<ins>Added</ins><img src="/images/emoji.png" onerror="alert(1)"><script>alert(1)</script>'
        element = $compile('<div tg-bo-html="html"></div>')(scope)
        scope.$digest()

        expect(element.find("ins")).to.have.text("Added")
        expect(element.find("script")).to.have.length(0)
        expect(element.find("img")).to.have.length(1)
        expect(element.find("img").attr("onerror")).to.be.undefined

    it "sanitizes changing subject HTML and keeps emoji images", ->
        scope = $rootScope.$new()
        scope.html = '<img src="/images/emoji.png" class="emoji"><svg onload="alert(1)"></svg>'
        element = $compile('<span tg-bind-html="html"></span>')(scope)
        scope.$digest()

        expect(element.find("img")).to.have.length(1)
        expect(element.find("svg")).to.have.length(0)

        scope.html = '<b>Updated</b><img src="/images/emoji.png" onerror="alert(1)">'
        scope.$digest()
        expect(element.find("b")).to.have.text("Updated")
        expect(element.find("img").attr("onerror")).to.be.undefined

        scope.html = null
        scope.$digest()
        expect(element.html()).to.equal("")
