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


describe "preference display filters", ->
    labels = filters = compile = rootScope = null

    beforeEach ->
        labels = {"THEMES.LIGHT": "Light", "THEMES.DARK": "Dark"}
        module "taigaCommon"
        module ($provide) ->
            $provide.value "$translate", {instant: (key) -> labels[key] || key}
            return null

        inject ($filter, $compile, $rootScope) ->
            filters = $filter
            compile = $compile
            rootScope = $rootScope

    it "uses translated names without changing theme identifiers", ->
        themeName = filters("themeName")
        expect(themeName("taiga")).to.equal("Light")
        expect(themeName("taiga-dark")).to.equal("Dark")
        expect(themeName("custom-theme")).to.equal("custom-theme")
        labels["THEMES.LIGHT"] = "Claro"
        expect(themeName("taiga")).to.equal("Claro")

    it "shows translated theme options while selecting the stored code", ->
        scope = rootScope.$new()
        scope.themes = ["taiga", "taiga-dark"]
        scope.theme = "taiga-dark"
        element = compile('<select ng-model="theme" ng-options="theme as (theme | themeName) for theme in themes"></select>')(scope)
        scope.$digest()
        expect(element[0].selectedOptions[0].textContent).to.equal("Dark")
        expect(scope.theme).to.equal("taiga-dark")

    it "shows locale names and keeps unknown codes readable", ->
        localeName = filters("localeName")
        locales = [{code: "en", name: "English (US)"}, {code: "pt-br", name: "Português (Brasil)"}]
        expect(localeName("pt-br", locales)).to.equal("Português (Brasil)")
        expect(localeName("en", locales)).to.equal("English (US)")
        expect(localeName("custom", locales)).to.equal("custom")
