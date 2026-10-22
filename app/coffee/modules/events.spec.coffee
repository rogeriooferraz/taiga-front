###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

describe "taigaEvents reconnect", ->
    events = null
    clock = null

    beforeEach ->
        module "taigaEvents"
        module ($provide) ->
            $provide.value "$tgConfig", {get: (key, fallback) -> fallback}
            $provide.value "$tgAuth", {getToken: -> "review-token"}
            $provide.value "tgLiveAnnouncementService", {show: sinon.spy()}
            return null

        inject (_$tgEvents_) ->
            events = _$tgEvents_
            events.sessionId = "review-session"
            events.ws = {send: sinon.spy()}

    afterEach ->
        events.stopHeartBeatMessages()
        clock?.restore()

    sentMessages = ->
        _.map(events.ws.send.args, (args) -> JSON.parse(args[0]))

    projectMessages = ->
        _.filter(sentMessages(), (message) ->
            message.routing_key == "changes.project.7.tasks")

    it "authenticates before replaying each active project subscription", ->
        events.subscribe(null, "changes.project.7.tasks", sinon.spy(), {
            selfNotification: true
        })
        events.onOpen()

        expect(sentMessages()[0].cmd).to.equal("auth")
        expect(projectMessages()).to.have.length(1)
        expect(projectMessages()[0].options.selfNotification).to.equal(true)
        expect(_.filter(sentMessages(), (message) ->
            message.routing_key == "notifications")).to.have.length(1)

        events.connected = false
        events.ws = {send: sinon.spy()}
        events.onOpen()

        expect(sentMessages()[0].cmd).to.equal("auth")
        expect(projectMessages()).to.have.length(1)
        expect(projectMessages()[0].options.selfNotification).to.equal(true)
        expect(_.filter(sentMessages(), (message) ->
            message.routing_key == "notifications")).to.have.length(1)

    it "does not replay a route removed while disconnected", ->
        events.subscribe(null, "changes.project.7.tasks", sinon.spy())
        events.error = true
        events.unsubscribe("changes.project.7.tasks")
        events.onOpen()

        expect(projectMessages()).to.have.length(0)

    it "replays a route requested during a connection failure", ->
        events.error = true
        events.subscribe(null, "changes.project.7.tasks", sinon.spy())
        events.onOpen()

        expect(projectMessages()).to.have.length(1)

    it "keeps a replacement subscription when an old scope is destroyed", ->
        oldDestroy = null
        oldScope = {$on: (event, callback) -> oldDestroy = callback}
        newScope = {$on: sinon.spy()}
        events.subscribe(oldScope, "changes.project.7.tasks", sinon.spy())
        events.subscribe(newScope, "changes.project.7.tasks", sinon.spy())
        oldDestroy()
        events.onOpen()

        expect(projectMessages()).to.have.length(1)

    it "retries by default after five failures and resets on open", ->
        clock = sinon.useFakeTimers()
        events.errors = 4
        events.randomTryInterval = -> 100
        events.setupConnection = sinon.spy()
        events.onError(new Error("broker unavailable"))
        clock.tick(100)

        expect(events.setupConnection).to.have.been.calledOnce
        events.onOpen()
        expect(events.errors).to.equal(0)

    it "honors a configured positive connection-error limit", ->
        clock = sinon.useFakeTimers()
        events.maxConnectionErrors = 5
        events.errors = 4
        events.setupConnection = sinon.spy()
        events.onError(new Error("broker unavailable"))
        clock.tick(60000)

        expect(events.setupConnection).not.to.have.been.called
