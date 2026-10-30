###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

class InstanceDefaultsController
    @.$inject = ["instanceDefaults", "$tgHttp", "$tgConfig", "$tgAuth", "$translate", "$window"]

    constructor: (instanceDefaults, @http, @config, @auth, @translate, @window) ->
        @data = instanceDefaults
        @language = @data.default_language || ""
        @theme = @data.default_theme || ""
        @saving = false
        @error = null

    languageAvailable: ->
        return @language and @data.languages.some (locale) => locale.code == @language

    themeAvailable: ->
        return @theme and @data.themes.includes(@theme)

    hasUnavailableChoice: ->
        return Boolean((@language and !@languageAvailable()) or
                       (@theme and !@themeAvailable()))

    effectiveLanguage: -> @language || @data.deployment_language
    effectiveTheme: -> @theme || @data.deployment_theme

    save: ->
        return if @saving or @hasUnavailableChoice()
        user = @auth.getUser()
        overriddenLanguage = user?.lang and
                             @effectiveLanguage() != user.lang and
                             @effectiveLanguage() != (@data.default_language || @data.deployment_language)
        overriddenTheme = user?.theme and
                          @effectiveTheme() != user.theme and
                          @effectiveTheme() != (@data.default_theme || @data.deployment_theme)
        @saving = true
        @error = null
        payload = {
            revision: @data.revision,
            default_language: @language || null,
            default_theme: @theme || null
        }
        @http.patch("#{@config.get('api')}instance-defaults/admin", payload)
        .then (result) =>
            if overriddenLanguage or overriddenTheme
                lines = [@translate.instant("SYSTEM_SETTINGS.APPLY_HELP")]
                profile = @translate.instant("USER_SETTINGS.MENU.SECTION_TITLE")
                if overriddenLanguage
                    label = @translate.instant("USER_PROFILE.FIELD.LANGUAGE")
                    choice = @translate.instant("USER_PROFILE.FIELD.LANGUAGE_DEFAULT")
                    lines.push("#{profile} → #{label}: #{choice}")
                if overriddenTheme
                    label = @translate.instant("USER_PROFILE.FIELD.THEME")
                    choice = @translate.instant("USER_PROFILE.FIELD.THEME_DEFAULT")
                    lines.push("#{profile} → #{label}: #{choice}")
                @window.alert(lines.join("\n\n"))
            @window.location.reload()
        , (error) =>
            @saving = false
            @error = if error.status == 409 then "SYSTEM_SETTINGS.CONFLICT" else "SYSTEM_SETTINGS.ERROR_SAVE"

angular.module("taigaUserSettings").controller("InstanceDefaultsController", InstanceDefaultsController)
