###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
###

describe "Backlog estimation template", ->
    $templateCache = null

    beforeEach ->
        module "templates"
        inject (_$templateCache_) ->
            $templateCache = _$templateCache_

    it "renders point names as text and retains total formatting", ->
        template = _.template($templateCache.get("common/estimation/us-estimation-total.html"))
        name = '<img src=x onerror=alert(1)>'
        element = $(template({editable: true, pointName: name, totalPoints: 8}))

        expect(element.find("img")).to.have.length(0)
        expect(element.find(".points-value")).to.have.text("#{name} / 8")
        expect(element.find(".points-value span")).to.have.text("8")

    it "renders totals without a selected role", ->
        template = _.template($templateCache.get("common/estimation/us-estimation-total.html"))
        element = $(template({editable: true, pointName: null, totalPoints: 5}))

        expect(element.find(".points-value")).to.have.text("5")
