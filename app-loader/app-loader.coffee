###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

window._version = "___VERSION___"

window.taigaConfig = {
    "api": "http://localhost:8000/api/v1/",
    "newsletterSubscriberUrl": "https://newsletter-subscriber.taiga.io",
    "eventsUrl": null,
    "tribeHost": null,
    "eventsMaxMissedHeartbeats": 5,
    "eventsHeartbeatIntervalTime": 60000,
    "debug": false,
    "defaultLanguage": "en",
    "themes": ["taiga", "taiga-legacy", "material-design", "high-contrast"],
    "defaultTheme": "taiga",
    "publicRegisterEnabled": true,
    "feedbackEnabled": true,
    "supportUrl": null,
    "privacyPolicyUrl": null,
    "termsOfServiceUrl": null,
    "maxUploadFileSize": null,
    "enableAsanaImporter": false,
    "enableGithubImporter": false,
    "enableJiraImporter": false,
    "enableTrelloImporter": false,
    "contribPlugins": [],
    "baseHref": "/"
}

window.taigaContribPlugins = []

window._decorators = []

window.addDecorator = (provider, decorator) ->
    window._decorators.push({provider: provider, decorator: decorator})

window.getDecorators = ->
    return window._decorators

loadStylesheet = (path) ->
    link = document.createElement('link')
    link.href = path
    link.type = 'text/css'
    link.rel = 'stylesheet'
    document.getElementsByTagName('head')[0].appendChild(link)

loadJS = (path) ->
    return new Promise (resolve, reject) ->
        script = document.createElement('script')
        script.type = 'text/javascript'
        script.src = path
        script.onload = resolve
        script.onerror = (err) ->
            reject(err, s)
        document.body.appendChild(script)

loadPlugin = (pluginPath) ->
    return new Promise (resolve, reject) ->
        success = (plugin) ->
            if plugin.isPack
                for item in plugin.plugins
                    window.taigaContribPlugins.push(item)
            else
                window.taigaContribPlugins.push(plugin)

            if plugin.css
                loadStylesheet(plugin.css)

            #dont' wait for css
            if plugin.js
                loadJS(plugin.js).then(resolve)
            else
                resolve()

        fail = (jqXHR, textStatus, errorThrown) ->
            console.error("Error loading plugin", pluginPath, errorThrown)

        fetch(pluginPath)
        .then((response) => response.json())
        .then(success, fail)

loadPlugins = (plugins) ->
    promises = []
    plugins.forEach (pluginPath) ->
        promises.push(loadPlugin(pluginPath))

    return Promise.all(promises)

mainLoad = ->
    emojisPromise = fetch("#{window._version}/emojis/emojis-data.json")
    .then((response) => response.json())
    .then (emojis) ->
        window.emojis = emojis
    if window.taigaConfig.contribPlugins.length > 0
        loadJS("#{window._version}/js/libs.js")
            .then(() => loadJS("#{window._version}/js/templates.js"))
            .then(() => loadPlugins(window.taigaConfig.contribPlugins))
            .then(() => loadApp(emojisPromise))
    else
        loadJS("#{window._version}/js/libs.js")
            .then(() => loadJS("#{window._version}/js/templates.js"))
            .then(() => loadApp(emojisPromise))

loadApp = (emojisPromise) ->
    loadJS("#{window._version}/js/elements.js").then () ->
        loadJS("#{window._version}/js/app.js").then () ->
            emojisPromise.then ->
                angular.bootstrap(document, ['taiga'])

isAvailableTheme = (theme) ->
    return window._taigaAvailableThemes.includes(theme) and
           window.taigaConfig.themes.includes(theme)

getInitialTheme = ->
    theme = window.taigaConfig.defaultTheme || "taiga"
    theme = "taiga" if !isAvailableTheme(theme)

    try
        user = JSON.parse(localStorage.getItem("userInfo"))
        theme = user.theme if user?.theme and isAvailableTheme(user.theme)
    catch error
        # A corrupt local preference must not stop the application.

    return theme

loadTheme = (theme) ->
    return new Promise (resolve, reject) ->
        link = document.getElementById("taiga-theme")
        if !link
            link = document.createElement("link")
            link.id = "taiga-theme"
            link.rel = "stylesheet"
            document.head.appendChild(link)

        link.onload = resolve
        link.onerror = reject
        link.href = "#{window._version}/styles/theme-#{theme}.css"

showLoadError = (message = "Taiga could not load.") ->
    loading = document.getElementById("taiga-loading")
    loading.textContent = message
    retry = document.createElement("button")
    retry.type = "button"
    retry.textContent = "Retry"
    retry.addEventListener "click", -> window.location.reload()
    loading.appendChild(retry)

startApp = ->
    theme = getInitialTheme()
    loadTheme(theme)
    .catch ->
        throw new Error("The default theme could not load") if theme == "taiga"
        window._taigaAvailableThemes = window._taigaAvailableThemes.filter (available) -> available != theme
        return loadTheme("taiga")
    .then ->
        document.body.classList.add("taiga-ready")
        mainLoad()
    .catch ->
        showLoadError()

loadInstanceDefaults = ->
    return Promise.resolve() if !window.taigaConfig.instanceDefaultsEnabled

    controller = new AbortController()
    timeout = setTimeout((-> controller.abort()), 5000)
    url = "#{window.taigaConfig.api}instance-defaults"
    return fetch(url, {cache: "no-store", signal: controller.signal})
    .then (response) ->
        throw new Error("Instance defaults unavailable") if !response.ok
        return response.json()
    .then (data) ->
        throw new Error("Invalid instance defaults") if !data? or
            !Number.isInteger(data.revision) or data.revision < 0

        localeCheck = Promise.resolve()
        if data.default_language?
            language = data.default_language
            throw new Error("Invalid instance language") if typeof language != "string" or
                !/^[a-z]{2}(-[a-z0-9]+)*$/.test(language)
            localeCheck = fetch("#{window._version}/locales/taiga/locale-#{language}.json",
                         {cache: "no-store", signal: controller.signal})
            .then (localeResponse) ->
                throw new Error("Instance language is not shipped") if !localeResponse.ok

        return localeCheck.then ->
            if data.default_theme?
                throw new Error("Instance theme is not shipped") if !isAvailableTheme(data.default_theme)
                window.taigaConfig.defaultTheme = data.default_theme
            window.taigaConfig.defaultLanguage = data.default_language if data.default_language?
            window._taigaInstanceDefaults = data
    .finally -> clearTimeout(timeout)

promise = fetch "conf.json", {cache: "no-store"}
promise = promise.then (response) ->
    throw new Error("conf.json could not load") if !response.ok
    return response.json()
promise = promise.then (data) ->
    window.taigaConfig = Object.assign({}, window.taigaConfig, data)
    window._taigaDeploymentDefaults = {
        language: window.taigaConfig.defaultLanguage,
        theme: window.taigaConfig.defaultTheme
    }

    base = document.querySelector('base')

    if base && window.taigaConfig.baseHref
        base.setAttribute("href", window.taigaConfig.baseHref)
    else if !base && window.taigaConfig.baseHref
        base = document.createElement('base')
        base.setAttribute("href", window.taigaConfig.baseHref)
        document.head.appendChild(base)

    return loadInstanceDefaults().then ->
        document.documentElement.lang = window.taigaConfig.defaultLanguage
        startApp()

promise.catch (error) ->
    console.error "Taiga bootstrap failed.", error
    showLoadError("Taiga settings are unavailable. Retry, or contact an administrator.")
