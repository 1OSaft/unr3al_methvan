
local meth, smokecolour, failedSkillcheck, Core, ptfx, registeredContext = 0, "exp_grd_flare", false, {}, {}, false
Core.Input = {}

---@param xPlayer table
---@param isNew boolean
---@param skin table
RegisterNetEvent('esx:playerLoaded',function(xPlayer, isNew, skin)
	TriggerEvent('unr3al_methvan:client:registerContext')
end)

---Toggles Custom camera when inside Van
---@param bool boolean
function toggleCam(bool)
    if bool then
        local coords = GetEntityCoords(cache.ped)
        local x, y, z = coords.x + GetEntityForwardX(cache.ped) * 0.9, coords.y + GetEntityForwardY(cache.ped) * 0.9, coords.z + 0.92
        local rot = GetEntityRotation(cache.ped, 2)
        local camRotation = rot + vector3(0.0, 0.0, 175.0)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", x, y, z, camRotation, 70.0)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 1000, 1, 1)
    else
        if cam then
            RenderScriptCams(false, true, 0, true, false)
            DestroyCam(cam, false)
            cam = nil
        end
    end
end
--Soon to be implemented
function playerAnim(dict,clip)
	local player = PlayerPedId()
	lib.requestAnimDict(dict, 500)
	TaskPlayAnim(player, dict, clip, 1.0, 1.0, -1, 8, -1, true, true, true)
	RemoveAnimDict(dict)
end

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

RegisterNetEvent('unr3al_methvan:client:drugged', function()
	SetTimecycleModifier("drug_drive_blend01")
	SetPedMotionBlur(PlayerPedId(), true)

	SetPedMovementClipset(PlayerPedId(), "MOVE_M@DRUNK@SLIGHTLYDRUNK", true)
	SetPedIsDrunk(PlayerPedId(), true)

	Wait(Config.DrugEffectLengh)
	ClearTimecycleModifier()
end)

---Opens a context and waits for its answer
---@param minigame integer
---@param netId integer
---@return integer | nil
lib.callback.register('unr3al_methvan:client:openContext', function(minigame, netId)
	local entity = NetworkGetEntityFromNetworkId(netId)
	if not DoesEntityExist(entity) then
		return
	end
	meth = 0
	lib.showContext('Event_0'..minigame)
	while (lib.getOpenContextMenu() == 'Event_0'..minigame) do
		if Config.Debug then print(lib.getOpenContextMenu()) end
		Wait(500)
	end
	if failedSkillcheck then
		failedSkillcheck = false
		TriggerServerEvent('unr3al_methvan:server:blow', GetPlayerServerId(PlayerId()), netId)
	end
	return meth
end)

---Gets a players methtype
---@param netId integer
---@return table | nil
lib.callback.register('unr3al_methvan:client:getMethType', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then
        return
    end
    local options = {}
    local i = 1
    for methTypes in pairs(Config.Items) do
        if methTypes ~= "EnableDifferentMethTypes" and methTypes ~= "Methlab" then
            options[i] = { label = methTypes, value = methTypes}
            i=i+1
        end
    end
    local methType = lib.inputDialog('Meth', {
        {type = 'select', label = 'Select meth recipe', description = 'Some input description', required = true, options = options},
    })
    if Config.Debug and methType then print("Meth type: "..tostring(methType[1])) end
    return methType
end)

---Performs the starting Skillcheck
---@param vehicle integer
---@return boolean
lib.callback.register('unr3al_methvan:client:skillcheck', function(vehicle)
	if Config.Debug then print("Starting Skillcheck") end
	local starting = false
	SetVehicleDoorOpen(vehicle, 2, false, false)
	if Config.SkillCheck.StartingProd.Enabled then
		Wait(1500)
		local success = lib.skillCheck(Config.SkillCheck.StartingProd.Difficulty, Config.SkillCheck.StartingProd.Key)

		if success then
			if Config.Debug then print('Started Meth production') end
			notifications(Config.Noti.success, Locales[Config.Locale]['Production_Started'], Config.Noti.time)
			if (Config.Cam) then
				toggleCam(true)
			end
			starting = true
		else
			notifications(Config.Noti.error, Locales[Config.Locale]['Failed_Start'], Config.Noti.time)
			Wait(1000)
			if Config.Debug then print('Failed start Skillcheck, blowing up') end
		end
	else
		if Config.Debug then print('Started Meth production') end
		notifications(Config.Noti.success, Locales[Config.Locale]['Production_Started'], Config.Noti.time)
		starting = true
	end
	return starting
end)

---Create smoke over the methvan
---@param stop boolean
---@param netId integer
RegisterNetEvent('unr3al_methvan:client:smoke', function(stop, netId)
	local entity = NetworkGetEntityFromNetworkId(netId)
	if not DoesEntityExist(entity) then
		return
	end
	if stop then
		Wait(2000)
        RemoveParticleFxFromEntity(entity)
        ptfx[entity] = nil
        return
    end
	if Config.SmokeColor == 'white' then
		smokecolour = "ent_amb_smoke_foundry_white"
	elseif Config.SmokeColor == 'orange' then
		smokecolour = "exp_grd_flare"
	elseif Config.SmokeColor == 'black' then
		smokecolour = "ent_amb_smoke_foundry"
	end
    lib.requestNamedPtfxAsset("core", 1000)
    UseParticleFxAsset("core")
    ptfx[entity] = StartParticleFxLoopedOnEntityBone(smokecolour, entity, 0.0, 0.13, 1.3, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(entity, 'chassis'), 3.0, false, false, false)
    SetParticleFxLoopedAlpha(ptfx[entity], 10.0)
end)

---Old notify event, needs to be replaced at some point
---@param notitype string
---@param message string
RegisterNetEvent('unr3al_methvan:client:notify', function(notitype, message)
	notifications(notitype, message, Config.Noti.time)
end)

---Stops the current production on client side
RegisterNetEvent('unr3al_methvan:client:stop', function()
	if (Config.Cam) then
		toggleCam(false)
	end
	DisplayHelpText(Locales[Config.Locale]['Production_Stoped'])
end)

---Blows the vehicle the player is in up, sync
---@param posx integer
---@param posy integer
---@param posz integer
---@param vehicle integer
---@param netId integer
RegisterNetEvent('unr3al_methvan:client:blowup', function(posx, posy, posz, vehicle, netId)
	local entity = NetworkGetEntityFromNetworkId(netId)
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	if not DoesEntityExist(entity) then
		return
	end
	if (Config.Cam) then
		toggleCam(false)
	end
	ExplodeVehicle(vehicle, true, false)
	NetworkExplodeVehicle(vehicle, true, false, true)
	SetVehicleEngineHealth(car, -4000)
	if not HasNamedPtfxAssetLoaded("core") then
		RequestNamedPtfxAsset("core")
		while not HasNamedPtfxAssetLoaded("core") do
			Wait(1)
		end
	end
	SetPtfxAssetNextCall("core")
	local fire = StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", posx, posy, posz-0.8 , 0.0, 0.0, 0.0, 0.8, false, false, false, false)
	Wait(6000)
	StopParticleFxLooped(fire, 0)
end)

RegisterNetEvent('unr3al_methvan:client:registerContext', function()
	lib.registerContext({
		id = 'Event_01',
		title = Locales[Config.Locale]['Question_01'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title =  Locales[Config.Locale]['Question_01_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					local pos = GetEntityCoords(PlayerPedId())
					if not Questions.DisableAll and Questions.Question_01.Enabled then
						if Questions.Question_01.DifficultyAnswer_1 == 0 then
						elseif Questions.Question_01.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_01_Fail'], Config.Noti.time)
								failedSkillcheck = true
							end
						elseif Questions.Question_01.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_01_Fail'], Config.Noti.time)
								failedSkillcheck = true
							end
						end
					end
					meth = -3
				end,
				icon = 'tape'
			},
			{
				title = Locales[Config.Locale]['Question_01_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
					
					lib.hideContext(true)
					Wait(20)

					local pos = GetEntityCoords(PlayerPedId())
					notifications(Config.Noti.error, Locales[Config.Locale]['Question_01_Fail'], Config.Noti.time)
					failedSkillcheck = true
					ApplyDamageToPed(PlayerPedId(), 90, false)
					if Config.Debug then print('Stopped making Drugs') end
				end,
				icon = 'circle-pause'
			},
			{
				title = Locales[Config.Locale]['Question_01_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_01.Enabled then
						if Questions.Question_01.DifficultyAnswer_3 == 0 then
							meth = 5
						elseif Questions.Question_01.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_01_Answer_3_1'], Config.Noti.time)
								meth = 5
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_01_Fail'], Config.Noti.time)
								failedSkillcheck = true
							end
						elseif Questions.Question_01.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_01_Answer_3_1'], Config.Noti.time)
								meth = 5
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_01_Fail'], Config.Noti.time)
								failedSkillcheck = true
							end
						end
					else
						meth = 5
					end
				end,
				icon = 'wrench'
			},
		},
	})
	lib.registerContext({
		id = 'Event_02',
		title = Locales[Config.Locale]['Question_02'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title = Locales[Config.Locale]['Question_02_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_02.Enabled then
						if Questions.Question_02.DifficultyAnswer_1 == 0 then
							meth = -1
						elseif Questions.Question_02.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_02_Answer_1_1'], Config.Noti.time)
								meth = -1
							else
								TriggerEvent('unr3al_methvan:client:drugged')
							end
						elseif Questions.Question_02.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_02_Answer_1_1'], Config.Noti.time)
								meth = -1
							else
								TriggerEvent('unr3al_methvan:client:drugged')
							end
						end
					else
						TriggerEvent('unr3al_methvan:client:drugged')
					end
				end,
				icon = 'window-maximize'
			},
			{
				title = Locales[Config.Locale]['Question_02_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
					
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_02_Answer_2_1'], Config.Noti.time)
					TriggerEvent('unr3al_methvan:client:drugged')
				end,
				icon = 'circle-pause'
			},
			{
				title = Locales[Config.Locale]['Question_02_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_02.Enabled then
						if Questions.Question_02.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
							SetPedPropIndex(playerPed, 1, 26, 7, true)
						elseif Questions.Question_02.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
								SetPedPropIndex(playerPed, 1, 26, 7, true)
							else
								TriggerEvent('unr3al_methvan:client:drugged')
							end
						elseif Questions.Question_02.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
								SetPedPropIndex(playerPed, 1, 26, 7, true)
							else
								TriggerEvent('unr3al_methvan:client:drugged')
							end
						end
					else
						notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
						SetPedPropIndex(playerPed, 1, 26, 7, true)
					end
				end,
				icon = 'mask-ventilator'
			},
		},
	})
	lib.registerContext({
		id = 'Event_03',
		title = Locales[Config.Locale]['Question_03'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title = Locales[Config.Locale]['Question_03_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideMenu(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_1_1'], Config.Noti.time)
				end,
				icon = 'burn'
			},
			{
				title = Locales[Config.Locale]['Question_03_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_03.Enabled then
						if Questions.Question_03.DifficultyAnswer_2 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
							meth = 5
						elseif Questions.Question_03.DifficultyAnswer_2 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
								meth = 5
							end
						elseif Questions.Question_03.DifficultyAnswer_2 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
								meth = 5
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
						meth = 5
					end
				end,
				icon = 'temperature-full'
			},
			{
				title = Locales[Config.Locale]['Question_03_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_03.Enabled then
						if Questions.Question_03.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
							meth = -4
						elseif Questions.Question_03.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								meth = -4
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								meth = -4
							end
						elseif Questions.Question_03.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								meth = -4
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								meth = -4
							end
						end
					else
						notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
						meth = -4
					end
				end,
				icon = 'temperature-quarter'
			},
		},
	})
	lib.registerContext({
		id = 'Event_04',
		title = Locales[Config.Locale]['Question_04'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title = Locales[Config.Locale]['Question_04_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end
					
					lib.hideMenu(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
					meth = -3
				end,
				icon = 'circle-pause'
			},
			{
				title = Locales[Config.Locale]['Question_04_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_04.Enabled then
						if Questions.Question_04.DifficultyAnswer_2 == 0 then
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
							meth = -1
						elseif Questions.Question_04.DifficultyAnswer_2 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								meth = -1
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								meth = -3
							end
						elseif Questions.Question_04.DifficultyAnswer_2 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								meth = -1
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								meth = -3
							end
						end
					else
						notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
						meth = -1
					end
				end,
				icon = 'syringe'
			},
			{
				title = Locales[Config.Locale]['Question_04_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_04.Enabled then
						if Questions.Question_04.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
							meth = 3
						elseif Questions.Question_04.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
								meth = 3
							else
								notifications(Config.Noti.error,Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
								meth = -3
							end
						elseif Questions.Question_04.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
								meth = 3
							else
								notifications(Config.Noti.error,Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
								meth = -3
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
						meth = 3
					end
				end,
				icon = 'car-battery'
			},
		},
	})
	lib.registerContext({
		id = 'Event_05',
		title = Locales[Config.Locale]['Question_05'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title = Locales[Config.Locale]['Question_05_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_05.Enabled then
						if Questions.Question_05.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
							meth = 4
						elseif Questions.Question_05.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
								meth = 4
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_1_2'], Config.Noti.time)
							end
						elseif Questions.Question_05.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
								meth = 4
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_1_2'], Config.Noti.time)
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
						meth = 4
					end
				end,
				icon = 'bottle-droplet'
			},
			{
				title = Locales[Config.Locale]['Question_05_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
										
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.info, Locales[Config.Locale]['Question_05_Answer_2_1'], Config.Noti.time)
				end,
				icon = 'trash'
			},
			{
				title = Locales[Config.Locale]['Question_05_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end
										
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_3_1'], Config.Noti.time)
				end,
				icon = 'bottle-droplet'
			},
		},
	})
	lib.registerContext({
		id = 'Event_06',
		title = Locales[Config.Locale]['Question_06'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title = Locales[Config.Locale]['Question_06_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end
					
					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_06.Enabled then
						if Questions.Question_06.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
						elseif Questions.Question_06.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_06_Answer_1_2'], Config.Noti.time)
								meth = -2
							end
						elseif Questions.Question_06.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_06_Answer_1_2'], Config.Noti.time)
								meth = -2
							end
						end
					else
						notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
					end
				end,
				icon = 'spray-can'
			},
			{
				title = Locales[Config.Locale]['Question_06_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
					
					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_06.Enabled then
						if Questions.Question_06.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
							meth = 3
						elseif Questions.Question_06.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
								meth = 3
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_06_Answer_2_2'], Config.Noti.time)
							end
						elseif Questions.Question_06.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
								meth = 3
							else
								notifications(Config.Noti.success, Locales[Config.error]['Question_06_Answer_2_2'], Config.Noti.time)
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
						meth = 3
					end	
				end,
				icon = 'wrench'
			},
			{
				title = Locales[Config.Locale]['Question_06_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_06.Enabled then
						if Questions.Question_06.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
							meth = -1
						elseif Questions.Question_06.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								meth = -1
							else
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								meth = -1
							end
						elseif Questions.Question_06.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								meth = -1
							else
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								meth = -1
							end
						end
					else
						notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
						meth = -1
					end
				end,
				icon = 'wrench'
			},
		},
	})
	lib.registerContext({
		id = 'Event_07',
		title = Locales[Config.Locale]['Question_07'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title = Locales[Config.Locale]['Question_07_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end
					
					lib.hideContext(true)
					Wait(20)
					
					notifications(Config.Noti.success, Locales[Config.Locale]['Question_07_Answer_1_1'], Config.Noti.time)
					meth = 1
				end,
				icon = 'face-grimace'
			},
			{
				title = Locales[Config.Locale]['Question_07_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
										
					lib.hideContext(true)
					Wait(20)
					
					notifications(Config.Noti.error, Locales[Config.Locale]['Question_07_Answer_2_1'], Config.Noti.time)
					meth = -2
				end,
				icon = 'tree'
			},
			{
				title = Locales[Config.Locale]['Question_07_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end
															
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_07_Answer_3_1'], Config.Noti.time)
					meth = -1
				end,
				icon = 'chair'
			},
		},
	})
	lib.registerContext({
		id = 'Event_08',
		title = Locales[Config.Locale]['Question_08'],
		onExit = function()
			Wait(20)
			TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question'},
			{
				title = Locales[Config.Locale]['Question_08_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_08.Enabled then
						if Questions.Question_08.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
							meth = 1
						elseif Questions.Question_08.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
								meth = 1
							else
								notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
								meth = 1
							end
						elseif Questions.Question_08.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
								meth = 1
							else
								notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
								meth = 1
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
						meth = 1
					end
				end,
				icon = 'wine-glass-empty'
			},
			{
				title = Locales[Config.Locale]['Question_08_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end

					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
					meth = 1
					
				end,
				icon = 'flask'
			},
			{
				title = Locales[Config.Locale]['Question_08_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end
					
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_08_Answer_3_1'], Config.Noti.time)
					meth = -1
				end,
				icon = 'wine-glass-empty'
			},
		},
	})
end)

RegisterInput = function(command_name, label, input_group, key, on_press, on_release)
    RegisterCommand(on_release ~= nil and "+" .. command_name or command_name, on_press)
    Core.Input[command_name] = on_release ~= nil and HashString("+" .. command_name) or HashString(command_name)
    if on_release then
        RegisterCommand("-" .. command_name, on_release)
    end
    RegisterKeyMapping(on_release ~= nil and "+" .. command_name or command_name, label, input_group, key)
end

HashString = function(str)
    local format = string.format
    local upper = string.upper
    local gsub = string.gsub
    local hash = joaat(str)
    local input_map = format("~INPUT_%s~", upper(format("%x", hash)))
    input_map = string.gsub(input_map, "FFFFFFFF", "")

    return input_map
end

if (Config.StartProduction.Key.Enabled) then
	RegisterInput("StartProduction", "Start meth production", "keyboard", Config.StartProduction.Key.StartKey, function()
		TriggerServerEvent('unr3al_methvan:server:start', NetworkGetNetworkIdFromEntity(cache.vehicle))
	end)
end

RegisterInput("StopProduction", "Stop meth production", "keyboard", "F", function()
	TriggerServerEvent('unr3al_methvan:server:stopProduction', GetPlayerServerId(PlayerId()), NetworkGetNetworkIdFromEntity(cache.vehicle))
end)

if (Config.Debug) then
	RegisterCommand('meth', function()
		ClearTimecycleModifier()
	end, false)
end
