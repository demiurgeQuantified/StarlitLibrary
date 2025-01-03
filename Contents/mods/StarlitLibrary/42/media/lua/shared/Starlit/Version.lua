local modInfo = getModInfoByID("\\StarlitLibrary")

local POPUP_HEIGHT = 100

local GAME_BUILD = getCore():getGameVersion():getMajor()

local CORE = getCore()
local TEXT_MANAGER = getTextManager()

local Version = {}

Version.VERSION_STRING = modInfo:getModVersion()

do
    local build, major, minor, patch = string.match(Version.VERSION_STRING, "(%d+)%-(%d+)%.(%d+)%.(%d+)")

    ---The major game build the current version of Starlit is designed for.
    ---@type integer
    Version.BUILD = tonumber(build) --[[@as integer]]
    ---The major version of Starlit. Major versions are incremented when non-trivial breaking changes are made to the API.
    ---@type integer
    Version.MAJOR = tonumber(major) --[[@as integer]]
    ---The minor version of Starlit. Minor versions are incremented when new features are added, and old features may be deprecated.
    ---@type integer
    Version.MINOR = tonumber(minor) --[[@as integer]]
    ---The patch version of Starlit. Patch versions are incremented by bug fixes that don't change (intended) functionality.
    ---@type integer
    Version.PATCH = tonumber(patch) --[[@as integer]]
end

---Compares the version specified to the current version.
---@param build integer Major game build.
---@param major integer Major version of Starlit.
---@param minor integer Minor version of Starlit.
---@param patch integer Patch version of Starlit.
---@return "toolow"|"toohigh"|"compatible" compatible A string indicating if the current version is compatible, or why it isn't.
---@nodiscard
Version.compareVersion = function(build, major, minor, patch)
    if Version.BUILD > build then
        return "toohigh"
    elseif Version.BUILD < build then
        return "toolow"
    end

    if Version.MAJOR > major then
        return "toohigh"
    elseif Version.MAJOR < major then
        return "toolow"
    end

    if Version.MINOR < minor then
        return "toolow"
    elseif Version.MINOR == minor and Version.PATCH < patch then
        return "toolow"
    end

    return "compatible"
end

---Compares the current version to the requested version, showing a popup to the user if it is not likely to be compatible.
---@param major integer Major version.
---@param minor integer Minor version.
---@param patch integer Patch version.
---@return "toolow"|"toohigh"|"compatible" compatible A string indicating if the current version is compatible, or why it isn't.
Version.ensureVersion = function(major, minor, patch)
    local compareResult = Version.compareVersion(GAME_BUILD, major, minor, patch)

    -- if compareResult ~= "compatible" then
    if compareResult == "toolow" then -- the too high message is probably just going to annoy people
        local text = compareResult == "toolow" and getText("IGUI_StarlitLibrary_VersionTooOld") or getText("IGUI_StarlitLibrary_VersionTooNew")
        local width = TEXT_MANAGER:MeasureStringX(UIFont.Small, text)
        local popup = ISModalDialog:new(
            (CORE:getScreenWidth() - width) / 2, (CORE:getScreenHeight() - POPUP_HEIGHT) / 2,
            width, POPUP_HEIGHT, text, false)
        popup:initialise()
        popup:addToUIManager()
    end

    return compareResult
end

return Version