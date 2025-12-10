---Deprecated. Use Starlit/LuaEvent instead.
---@deprecated
return require("Starlit/LuaEvent")

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