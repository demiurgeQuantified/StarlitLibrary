local Config = {
    keys = {
        openDebugMenu = nil
    }
}

if getDebug() then
    local modOptions = PZAPI.ModOptions:create(
        "Starlit",
        getText("UI_StarlitLibrary")
    )

    local openDebugMenu = modOptions:addKeyBind(
        "DebugMenuKey",
        getText("UI_StarlitLibrary_Options_DebugMenuKey"),
        nil,
        getText("UI_StarlitLibrary_Options_DebugMenuKey_tooltip")
    )

    modOptions.apply = function()
        Config.keys.openDebugMenu = openDebugMenu.key
    end

    Events.OnGameStart.Add(modOptions.apply)
end

return Config