###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
###

describe "public register message", ->
    $compile = $rootScope = config = routeParams = template = null

    beforeEach ->
        config = {get: sinon.stub().returns(true)}
        routeParams = {}
        template = sinon.spy(_, "template")
        module "taigaAuth", "taigaCommon", "templates", "pascalprecht.translate"
        module ($provide) ->
            # Keep the authentication module's resource startup outside this
            # directive check.
            resourceProviders = [
                "$tgProjectsResourcesProvider"
                "$tgCustomAttributesResourcesProvider"
                "$tgCustomAttributesValuesResourcesProvider"
                "$tgMembershipsResourcesProvider"
                "$tgNotifyPoliciesResourcesProvider"
                "$tgInvitationsResourcesProvider"
                "$tgRolesResourcesProvider"
                "$tgUserProjectSettingsResourcesProvider"
                "$tgUserSettingsResourcesProvider"
                "$tgSprintsResourcesProvider"
                "$tgEpicsResourcesProvider"
                "$tgUserstoriesResourcesProvider"
                "$tgTasksResourcesProvider"
                "$tgIssuesResourcesProvider"
                "$tgSwimlanesResourcesProvider"
                "$tgWikiResourcesProvider"
                "$tgSearchResourcesProvider"
                "$tgMdRenderResourcesProvider"
                "$tgHistoryResourcesProvider"
                "$tgKanbanResourcesProvider"
                "$tgModulesResourcesProvider"
                "$tgWebhooksResourcesProvider"
                "$tgWebhookLogsResourcesProvider"
                "$tgLocalesResourcesProvider"
                "$tgUsersResourcesProvider"
            ]
            for name in resourceProviders
                $provide.value name, ->
            $provide.value "$tgResources", {}
            $provide.value "$tgUrls", {update: ->}
            $provide.value "$tgConfig", config
            $provide.value "$tgNavUrls", {
                update: ->
                resolve: -> "/register"
            }
            $provide.value "$routeParams", routeParams
            return null

        inject (_$compile_, _$rootScope_) ->
            $compile = _$compile_
            $rootScope = _$rootScope_

    afterEach ->
        template.restore()

    render = ->
        scope = $rootScope.$new()
        element = $compile("<tg-public-register-message></tg-public-register-message>")(scope)
        scope.$digest()
        return element

    it "links to registration without compiling a Lodash template", ->
        element = render()

        expect(element.find("a")).to.have.attr("href", "/register")
        expect(template).not.to.have.been.called

    it "keeps a forced next path encoded in the registration URL", ->
        routeParams.force_next = '/project?name=<img src=x>&mode=all'
        element = render()

        expect(element.find("a")).to.have.attr("href",
            "/register?next=%2Fproject%3Fname%3D%3Cimg%20src%3Dx%3E%26mode%3Dall")
        expect(element.find("img")).to.have.length(0)

    it "hides registration when public registration is disabled", ->
        config.get.returns(false)
        element = render()

        expect(element.find("a")).to.have.length(0)
