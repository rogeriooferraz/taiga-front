###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

describe "dropdownUserDirective", () ->
    scope = compile = provide = null
    mockTgAuth = null
    mockTgConfig = null
    mockTgLocation = null
    mockTgNavUrls = null
    mockTgFeedbackService = null
    httpService = null
    q = null
    template = "<div tg-dropdown-user></div>"

    createDirective = () ->
        elm = compile(template)(scope)
        return elm

    _mockTranslateFilter = () ->
        mockTranslateFilter = (value) ->
            return value
        provide.value "translateFilter", mockTranslateFilter

    _mockTgAuth = () ->
        mockTgAuth = {
            userData: Immutable.fromJS({id: 66})
            logout: sinon.stub()
            isAuthenticated: sinon.stub().returns(true)
        }
        provide.value "$tgAuth", mockTgAuth

    _mockTgConfig = () ->
        mockTgConfig = {
            get: sinon.stub()
        }
        provide.value "$tgConfig", mockTgConfig

    _mockTgLocation = () ->
        mockTgLocation = {
            url: sinon.stub()
            search: sinon.stub()
        }

        provide.value "$tgLocation", mockTgLocation

    _mockTgNavUrls = () ->
        mockTgNavUrls = {
            resolve: sinon.stub()
        }
        provide.value "$tgNavUrls", mockTgNavUrls

    _mockTgHttp = () ->
        httpService = {get: sinon.stub()}
        provide.value "$tgHttp", httpService

    _mocks = () ->
        module ($provide) ->
            provide = $provide
            _mockTranslateFilter()
            _mockTgAuth()
            _mockTgConfig()
            _mockTgLocation()
            _mockTgNavUrls()
            _mockTgHttp()
            return null

    beforeEach ->
        module "templates"
        module "taigaNavigationBar"

        _mocks()

        inject ($rootScope, $compile, $q) ->
            scope = $rootScope.$new()
            compile = $compile
            q = $q

    it "dropdown user directive scope content", () ->
        mockTgConfig.get.withArgs("feedbackEnabled").returns(true)
        elm = createDirective()
        scope.$apply()

        vm = elm.isolateScope().vm
        expect(vm.user.get("id")).to.be.equal(66)
        expect(vm.isFeedbackEnabled).to.be.equal(true)

    it "dropdown user log out", () ->
        mockTgNavUrls.resolve.withArgs("discover").returns("/discover")
        elm = createDirective()
        scope.$apply()
        vm = elm.isolateScope().vm
        expect(mockTgAuth.logout.callCount).to.be.equal(0)
        expect(mockTgLocation.url.callCount).to.be.equal(0)
        expect(mockTgLocation.search.callCount).to.be.equal(0)
        vm.logout()
        expect(mockTgAuth.logout.callCount).to.be.equal(1)
        expect(mockTgLocation.url.callCount).to.be.equal(1)
        expect(mockTgLocation.search.callCount).to.be.equal(1)
        expect(mockTgLocation.url.calledWith("/discover")).to.be.true
        expect(mockTgLocation.search.calledWith({})).to.be.true

    it "shows system settings only after an administrator capability response", () ->
        mockTgConfig.get.withArgs("instanceDefaultsEnabled").returns(true)
        mockTgConfig.get.withArgs("api").returns("/api/v1/")
        deferred = q.defer()
        httpService.get.returns(deferred.promise)
        elm = createDirective()
        scope.$apply()
        vm = elm.isolateScope().vm
        expect(vm.canManageInstance).to.be.false
        expect(httpService.get.calledWith("/api/v1/instance-defaults/admin")).to.be.true
        deferred.resolve({data: {}})
        scope.$apply()
        expect(vm.canManageInstance).to.be.true

    it "hides system settings after a denied capability response", () ->
        mockTgConfig.get.withArgs("instanceDefaultsEnabled").returns(true)
        mockTgConfig.get.withArgs("api").returns("/api/v1/")
        deferred = q.defer()
        httpService.get.returns(deferred.promise)
        elm = createDirective()
        scope.$apply()
        deferred.reject({status: 403})
        scope.$apply()
        expect(elm.isolateScope().vm.canManageInstance).to.be.false

    it "checks capability after login and clears it after logout", () ->
        mockTgConfig.get.withArgs("instanceDefaultsEnabled").returns(true)
        mockTgConfig.get.withArgs("api").returns("/api/v1/")
        mockTgAuth.isAuthenticated.returns(false)
        deferred = q.defer()
        httpService.get.returns(deferred.promise)
        elm = createDirective()
        scope.$apply()
        expect(httpService.get.called).to.be.false
        mockTgAuth.isAuthenticated.returns(true)
        scope.$broadcast("auth:login")
        scope.$apply()
        expect(httpService.get.calledOnce).to.be.true
        deferred.resolve({data: {}})
        scope.$apply()
        expect(elm.isolateScope().vm.canManageInstance).to.be.true
        scope.$broadcast("auth:logout")
        scope.$apply()
        expect(elm.isolateScope().vm.canManageInstance).to.be.false
