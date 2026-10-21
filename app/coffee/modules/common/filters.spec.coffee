###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
###

describe "emojify filter", ->
    $compile = $rootScope = null

    beforeEach ->
        module "taigaCommon", "ngSanitize"
        module ($provide) ->
            $provide.value "$tgEmojis", {
                replaceEmojiNameByHtmlImgs: (text) ->
                    text.replace(/:smile:/g, '<img src="/images/emoji.png">')
            }
            return null

        inject (_$compile_, _$rootScope_) ->
            $compile = _$compile_
            $rootScope = _$rootScope_

    it "shows literal subject markup and still renders emoji images", ->
        scope = $rootScope.$new()
        scope.subject = '<img src="https://example.invalid/track"> :smile:'
        element = $compile('<span ng-bind-html="subject | emojify"></span>')(scope)
        scope.$digest()

        expect(element.text()).to.contain('<img src="https://example.invalid/track">')
        expect(element.find("img")).to.have.length(1)
        expect(element.find("img").attr("src")).to.equal("/images/emoji.png")
