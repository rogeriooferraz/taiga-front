###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
###

describe "backlog doom line", ->
    $rootScope = directive = template = null
    label = '<img src=x onerror=alert(1)> & "scope"'

    beforeEach ->
        template = sinon.spy(_, "template")
        module "taigaBacklog"
        module ($provide) ->
            $provide.value "$translate", {instant: -> label}
            $provide.value "$tgRepo", {}
            $provide.value "$tgResources", {}
            return null

        inject (_$rootScope_, _tgBacklogDirective_) ->
            $rootScope = _$rootScope_
            directive = _tgBacklogDirective_[0]

    afterEach ->
        template.restore()

    it "renders translated text without compiling a template", ->
        scope = $rootScope.$new()
        scope.stats = {total_points: 5, assigned_points: 0}
        scope.userstories = [{total_points: 8}]
        element = angular.element("""
            <div>
                <div class="backlog-table-body">
                    <div class="us-item-row"></div>
                </div>
            </div>
        """)
        element.controller = -> {location: {search: -> {}}}

        directive.link(scope, element)
        scope.$digest()

        doomLine = element.find(".doom-line")
        expect(doomLine).to.have.length(1)
        expect(doomLine.find("span")).to.have.text(label)
        expect(doomLine.find("img")).to.have.length(0)
        expect(element.find(".backlog-table-body").children().first()).to.have.attr("class", "doom-line")
        expect(template).not.to.have.been.called

        scope.displayVelocity = true
        scope.$broadcast("userstories:loaded")
        expect(element.find(".doom-line")).to.have.length(0)
        scope.$destroy()
