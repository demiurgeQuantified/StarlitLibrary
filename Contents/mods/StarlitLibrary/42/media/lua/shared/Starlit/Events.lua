---Object oriented reimplementation of events. Performs slightly faster and fixes some bugs as well as providing some utilities
---@class Starlit.LuaEvent
---@field [integer] function
local LuaEvent = {}
---@type table<string, Starlit.LuaEvent>
LuaEvent.list = {}
LuaEvent.__index = LuaEvent

---Creates a new event and registers it in the event list
---@param name string? Name of the event. If nil it will not be registered to the event list.
---@return Starlit.LuaEvent
LuaEvent.new = function(name)
    local o = table.newarray() --[[@as table]]

    setmetatable(o, LuaEvent)
    if name then
        LuaEvent.list[name] = o
    end

    return o
end

---Adds a new listener to be executed last
---@param listener function The listener
LuaEvent.addListener = function(self, listener)
    if not listener then return end
    table.insert(self, 1, listener)
end

---Adds a new listener to be executed first
---@param listener function The listener
LuaEvent.addListenerFront = function(self, listener)
    self[#self+1] = listener
end

---Adds a new listener to be executed before the target. Does nothing if the target is not a registered listener
---@param target function
---@param listener function
LuaEvent.addListenerBefore = function(self, target, listener)
    if not listener then return end
    for i = 1, #self do
        if self[i] == target then
            table.insert(self, i+1, listener)
            return
        end
    end
end

---Adds a new listener to be executed after the target. Does nothing if the target is not a registered listener
---@param target function
---@param listener function
LuaEvent.addListenerAfter = function(self, target, listener)
    if not listener then return end
    for i = 1, #self do
        if self[i] == target then
            table.insert(self, i, listener)
            return
        end
    end
end

---Removes all instances of a listener from execution.
---@param target function
LuaEvent.removeListener = function(self, target)
    for i = #self, 1, -1 do
        if self[i] == target then
            table.remove(self, i)
        end
    end
end

---Removes all event listeners
LuaEvent.removeAllListeners = function(self)
    for i = 1, #self do
        self[i] = nil
    end
end

---Triggers all event listener functions with the arguments passed
LuaEvent.trigger = function(self, ...)
    for i = #self, 1, -1 do
        self[i](...)
    end
end

----------------------------------------------------------------
-- vanilla compat
----------------------------------------------------------------

-- this doesn't work very well so i'm turning it off for now

-- ---@param luaEvent Starlit.LuaEvent
-- ---@return table
-- local getVanillaEventWrapper = function(luaEvent)
--     local event = {}

--     ---@param listener function
--     event.Add = function(listener)
--         luaEvent:addListener(listener)
--     end

--     ---@param target function
--     event.Remove = function(target)
--         luaEvent:removeListener(target)
--     end

--     return event
-- end

-- ---@param name string
-- triggerEvent = function(name, ...)
--     local event = LuaEvent.list[name]
--     if not event then return end
--     event:trigger(...)
-- end

-- local old_addEvent = LuaEventManager.AddEvent
-- ---@param name string
-- ---@diagnostic disable-next-line: duplicate-set-field
-- LuaEventManager.AddEvent = function(name)
--     local event = LuaEvent.new(name)

--     -- still need to add it for real incase the event is triggered from java
--     old_addEvent(name)
--     Events[name].Add(function(...) event:trigger(...) end)

--     Events[name] = getVanillaEventWrapper(event)
-- end

-- -- Unregister vanilla event listeners added before this file ran

-- -- Definitions/DamageModelDefinitions
-- Events.OnHitZombie.Remove(DamageModelDefinitions.OnHitZombie);

--     -- Foraging/forageSystem
-- if not isServer() then
--     Events.OnLoadedMapZones.Remove(forageSystem.init);
-- end

-- -- Joypad/JoyPadSetup
-- if not isServer() then
--     Events.OnGamepadConnect.Remove(JoypadState.onGamepadConnect)
--     Events.OnGamepadDisconnect.Remove(JoypadState.onGamepadDisconnect)
--     Events.OnJoypadActivate.Remove(onJoypadActivate);
--     Events.OnJoypadActivateUI.Remove(onJoypadActivateUI);
--     Events.OnJoypadBeforeDeactivate.Remove(onJoypadBeforeDeactivate);
--     Events.OnJoypadDeactivate.Remove(onJoypadDeactivate);
--     Events.OnJoypadBeforeReactivate.Remove(onJoypadBeforeReactivate);
--     Events.OnJoypadReactivate.Remove(onJoypadReactivate);
--     Events.OnRenderTick.Remove(onJoypadRenderTick);
--     Events.OnGameStart.Remove(JoypadState.onGameStart);
--     Events.OnCoopJoinFailed.Remove(JoypadState.onCoopJoinFailed)
--     Events.OnJoypadRenderUI.Remove(JoypadState.onRenderUI)
-- end

-- -- Logs/ISLogSystem
-- if isServer() then Events.OnClientCommand.Remove(ISLogSystem.OnClientCommand); end;

-- -- Logs/ISPerkLog
-- if isClient() then Events.EveryOneMinute.Remove(ISPerkLog.init); end;

-- -- NPCs/MainCreationMethods
-- Events.OnCreateSurvivor.Remove(BaseGameCharacterDetails.CreateCharacterInstance);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoTraits);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoProfessions);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoSpawnPoint);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoObservations);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoSurname);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoFemaleForename);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoMaleForename);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoTrouserColor);
-- Events.OnGameBoot.Remove(BaseGameCharacterDetails.DoHairColor);

-- -- RecordedMedia/ISRecordeMedia
-- Events.OnInitRecordedMedia.Remove(ISRecordedMedia.init);

-- -- Reloading/ISReloadManager
-- if not getCore():isNewReloading() then
--     Events.OnPlayerUpdate.Remove(aaa.startRackingHook);
--     Events.OnPlayerUpdate.Remove(aaa.startReloadHook);
--     Events.OnWeaponSwingHitPoint.Remove(aaa.fireShotHook);
-- end

-- -- SoundBanks/SoundBanks
-- Events.OnLoadSoundBanks.Remove(doLoadSoundbanks);

-- for name,event in pairs(Events) do
--     local luaEvent = LuaEvent.new(name)

--     event.Add(function(...) luaEvent:trigger(...) end)

--     Events[name] = getVanillaEventWrapper(luaEvent)
-- end

-- -- Definitions/DamageModelDefinitions
-- Events.OnHitZombie.Add(DamageModelDefinitions.OnHitZombie);

-- -- Foraging/forageSystem
-- if not isServer() then
--     Events.OnLoadedMapZones.Add(forageSystem.init);
-- end

-- -- Joypad/JoyPadSetup
-- if not isServer() then
--     Events.OnGamepadConnect.Add(JoypadState.onGamepadConnect)
--     Events.OnGamepadDisconnect.Add(JoypadState.onGamepadDisconnect)
--     Events.OnJoypadActivate.Add(onJoypadActivate);
--     Events.OnJoypadActivateUI.Add(onJoypadActivateUI);
--     Events.OnJoypadBeforeDeactivate.Add(onJoypadBeforeDeactivate);
--     Events.OnJoypadDeactivate.Add(onJoypadDeactivate);
--     Events.OnJoypadBeforeReactivate.Add(onJoypadBeforeReactivate);
--     Events.OnJoypadReactivate.Add(onJoypadReactivate);
--     Events.OnRenderTick.Add(onJoypadRenderTick);
--     Events.OnGameStart.Add(JoypadState.onGameStart);
--     Events.OnCoopJoinFailed.Add(JoypadState.onCoopJoinFailed)
--     Events.OnJoypadRenderUI.Add(JoypadState.onRenderUI)
-- end

-- -- Logs/ISLogSystem
-- if isServer() then Events.OnClientCommand.Add(ISLogSystem.OnClientCommand); end;

-- -- Logs/ISPerkLog
-- if isClient() then Events.EveryOneMinute.Add(ISPerkLog.init); end;

-- -- NPCs/MainCreationMethods
-- Events.OnCreateSurvivor.Add(BaseGameCharacterDetails.CreateCharacterInstance);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoTraits);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoProfessions);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoSpawnPoint);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoObservations);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoSurname);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoFemaleForename);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoMaleForename);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoTrouserColor);
-- Events.OnGameBoot.Add(BaseGameCharacterDetails.DoHairColor);

-- -- RecordedMedia/ISRecordeMedia
-- Events.OnInitRecordedMedia.Add(ISRecordedMedia.init);

-- -- Reloading/ISReloadManager
-- if not getCore():isNewReloading() then
--     Events.OnPlayerUpdate.Add(aaa.startRackingHook);
--     Events.OnPlayerUpdate.Add(aaa.startReloadHook);
--     Events.OnWeaponSwingHitPoint.Add(aaa.fireShotHook);
-- end

-- -- SoundBanks/SoundBanks
-- Events.OnLoadSoundBanks.Add(doLoadSoundbanks);

return LuaEvent