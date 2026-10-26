###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

class InstanceDefaultsController
    @.$inject = ["instanceDefaults", "$tgHttp", "$tgConfig", "$window"]

    constructor: (instanceDefaults, @http, @config, @window) ->
        @data = instanceDefaults
        @language = @data.default_language || ""
        @theme = @data.default_theme || ""
        @saving = false
        @error = null

    effectiveLanguage: -> @language || @data.deployment_language
    effectiveTheme: -> @theme || @data.deployment_theme

    save: ->
        return if @saving
        @saving = true
        @error = null
        payload = {
            revision: @data.revision,
            default_language: @language || null,
            default_theme: @theme || null
        }
        @http.patch("#{@config.get('api')}instance-defaults/admin", payload)
        .then (result) =>
            @window.location.reload()
        , (error) =>
            @saving = false
            @error = if error.status == 409 then "SYSTEM_SETTINGS.CONFLICT" else "SYSTEM_SETTINGS.ERROR_SAVE"

angular.module("taigaUserSettings").controller("InstanceDefaultsController", InstanceDefaultsController)
