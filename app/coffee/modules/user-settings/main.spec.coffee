###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
###

describe "User settings inheritance", ->
    scope = user = config = null

    beforeEach ->
        module "taigaUserSettings"

        inject ($controller, $rootScope, $q) ->
            scope = $rootScope.$new()
            user = {lang: "", theme: ""}
            config = {
                get: (name, fallback) ->
                    return ["taiga", "taiga-dark"] if name == "themes"
                    return "taiga" if name == "defaultTheme"
                    return fallback
            }
            window._taigaAvailableThemes = ["taiga", "taiga-dark"]
            $controller "UserSettingsController", {
                "$scope": scope
                "$rootScope": $rootScope
                "$tgConfig": config
                "$tgRepo": {}
                "$tgConfirm": {}
                "$tgResources": {locales: {list: -> $q.when([])}}
                "$routeParams": {}
                "$q": $q
                "$tgLocation": {}
                "$tgNavUrls": {}
                "$tgAuth": {getUser: -> user}
                "$translate": {preferredLanguage: -> "pt-br"}
                "tgErrorHandlingService": {}
                "$window": window
            }

    it "keeps blank account choices while showing effective defaults", ->
        expect(scope.lang).to.equal("")
        expect(scope.theme).to.equal("")
        expect(scope.effectiveLang).to.equal("pt-br")
        expect(scope.effectiveTheme).to.equal("taiga")
