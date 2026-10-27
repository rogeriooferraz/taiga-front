###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
###

describe "Instance defaults controller", ->
    controller = http = deferred = rootScope = null
    browser = null

    beforeEach ->
        module "taigaUserSettings"

        inject ($controller, $q, $rootScope) ->
            rootScope = $rootScope
            deferred = $q.defer()
            http = {patch: sinon.stub().returns(deferred.promise)}
            browser = {location: {reload: sinon.spy()}}
            controller = $controller "InstanceDefaultsController", {
                instanceDefaults: {
                    default_language: null
                    default_theme: null
                    deployment_language: "en"
                    deployment_theme: "taiga"
                    languages: [{code: "en"}, {code: "fr"}]
                    themes: ["taiga", "taiga-dark"]
                    revision: 3
                }
                "$tgHttp": http
                "$tgConfig": {get: -> "/api/v1/"}
                "$window": browser
            }

    it "saves cleared overrides with the current revision and reloads", ->
        expect(controller.effectiveLanguage()).to.equal("en")
        expect(controller.effectiveTheme()).to.equal("taiga")
        controller.save()
        expect(http.patch.calledOnce).to.be.true
        expect(http.patch.firstCall.args[0]).to.equal("/api/v1/instance-defaults/admin")
        expect(http.patch.firstCall.args[1]).to.deep.equal({
            revision: 3
            default_language: null
            default_theme: null
        })
        deferred.resolve({data: {revision: 4}})
        rootScope.$apply()
        expect(browser.location.reload.calledOnce).to.be.true

    it "shows a conflict without reloading or issuing a second write", ->
        controller.language = "fr"
        controller.theme = "taiga-dark"
        controller.save()
        controller.save()
        expect(http.patch.calledOnce).to.be.true
        expect(http.patch.firstCall.args[1]).to.deep.equal({
            revision: 3
            default_language: "fr"
            default_theme: "taiga-dark"
        })
        deferred.reject({status: 409})
        rootScope.$apply()
        expect(controller.error).to.equal("SYSTEM_SETTINGS.CONFLICT")
        expect(controller.saving).to.be.false
        expect(browser.location.reload.called).to.be.false

    it "shows deployment values for saved choices no longer available", ->
        controller.language = "pt-br"
        controller.theme = "removed-theme"
        expect(controller.languageAvailable()).to.be.false
        expect(controller.themeAvailable()).to.be.false
        expect(controller.effectiveLanguage()).to.equal("en")
        expect(controller.effectiveTheme()).to.equal("taiga")
        expect(controller.hasUnavailableChoice()).to.be.true
        controller.save()
        expect(http.patch.called).to.be.false

        controller.language = ""
        controller.theme = ""
        expect(controller.hasUnavailableChoice()).to.be.false
        controller.save()
        expect(http.patch.calledOnce).to.be.true
