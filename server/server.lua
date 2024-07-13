print("Unr3al Meth by 1OSaft")
local invstate = GetResourceState('ox_inventory')
if (invstate == 'started' and Config.Debug) then
	print("ox_inventory detected")
end

local methMakers = {}

AddEventHandler('playerDropped', function()
    if methMakers[source] then
        methMakers[source] = nil
    end
end)

if (Config.StartProduction.Item.Enabled) then
	ESX.RegisterUsableItem(Config.StartProduction.Item.ItemName, function(source)
		local xPlayer = ESX.GetPlayerFromId(source)
		if (Config.StartProduction.Item.ConsumeOnStart) then
			xPlayer.removeInventoryItem(Config.StartProduction.Item.ItemName, 1)
		end
		TriggerEvent('unr3al_methvan:server:start')
	end)
end

---Stops the production on server side
---@param source string
---@param netId integer
RegisterNetEvent('unr3al_methvan:server:stopProduction', function(source, netId)
	local entity = NetworkGetEntityFromNetworkId(netId)
	local src = source
	if not DoesEntityExist(entity) or not methMakers[src] then
		return
	end
	TriggerClientEvent('unr3al_methvan:client:stop', src, netId)
	local Player = ESX.GetPlayerFromId(src)
	local Players = ESX.GetExtendedPlayers()

	for k, Player in pairs(Players) do
		TriggerClientEvent('unr3al_methvan:client:smoke', Player.source, true, netId)
	end
	FreezeEntityPosition(methMakers[src].vehicle, false)
	methMakers[src] = nil
end)

---Starts the production process on server side
---@param netId string
RegisterServerEvent('unr3al_methvan:server:start', function(netId)
	local src = source
	local entity = NetworkGetEntityFromNetworkId(netId)
	local ped = GetPlayerPed(src)
    local canContinue = false
    local Player = ESX.GetPlayerFromId(src)
	local vehicle = GetVehiclePedIsIn(ped, false)

    if methMakers[src] or not DoesEntityExist(entity) or GetEntityModel(entity) ~= `journey` then
        return
    end
	if not GetPedInVehicleSeat(vehicle, 2) == 0 or not GetPedInVehicleSeat(vehicle, 2) == ped then
		return
	end
	local cops = ESX.GetExtendedPlayers('job', Config.Police)
	if #cops < Config.PoliceCount then
		TriggerClientEvent('unr3al_methvan:client:notify', src, Config.Noti.error, Locales[Config.Locale]['Not_Enough_Cops'])
		return
	end
	local input = {}
	if not Config.Items.EnableDifferentMethTypes then
		input = lib.callback.await('unr3al_methvan:client:getMethType', src, netId)
	else
		input[1] = 'Easy'
	end
	
	if not input then
		return
	end
	methType = input [1]
	if Config.Debug then print("Trying to remove Players Items") end

	local Enough = true
	for kItem, vCount in pairs(Config.Items[methType].Ingredients) do
		local item = Player.hasItem(kItem)
		if item.count >= vCount then
		else
			Enough = false
		end
	end
	local methlab = Player.hasItem(Config.Items.Methlab)
	if Enough and methlab.count >= 1 then
		for kItem, vCount in pairs(Config.Items[methType].Ingredients) do
			Player.removeInventoryItem(kItem, vCount)
		end
		canContinue = true
		if Config.Debug then print("Removed Starting Items") end
	else
		TriggerClientEvent('unr3al_methvan:client:notify', src, Config.Noti.error, Locales[Config.Locale]['Not_Supplies'])
	end

	if canContinue then
		FreezeEntityPosition(entity, true)
		SetPedIntoVehicle(ped, vehicle, 2)

		local success = lib.callback.await('unr3al_methvan:client:skillcheck', src, vehicle)
		if success then
			methMakers[src] = { vehicle = entity, progress = 0, quality = 0, methType = methType, paused = false, }
			TriggerEvent('unr3al_methvan:server:production', source, netId)
			if Config.Debug then print("Methtype: "..methType) end

			if Config.LogType == 'discord' then
				DiscordLogs("start", "Started Cooking", "green", {
					{name = "Player Informations", value = " ", inline = false},
					{name = "ID", value = tostring(src), inline = true},
					{name = "Name", value = tostring(xPlayer.name), inline = true},
					{name = "Identifier", value = tostring(xPlayer.identifier), inline = true},
					{name = "Cords", value = " ", inline = false},
					{name = "X", value = tostring(pos.x), inline = true},
					{name = "Y", value = tostring(pos.y), inline = true},
					{name = "Z", value = tostring(pos.z), inline = true},
				})
			elseif Config.LogType == 'ox_lib' then
				lib.logger(xPlayer.identifier, 'Started Cooking Meth', 'Started Cooking at: '..tostring(pos))
			elseif Config.LogType == 'disabled' then
			else print("MISSING LOG TYPE") end
		else
			--Blow
			TriggerEvent('unr3al_methvan:server:blow', source, netId)
		end
	end
end)

---Blows up a vehicle
---@param source string
---@param netId integer
RegisterServerEvent('unr3al_methvan:server:blow', function(source, netId)
	local src = source
	local entity = NetworkGetEntityFromNetworkId(netId)
	local pos = GetEntityCoords(entity)
	local Players = ESX.GetExtendedPlayers()
	local Player = ESX.GetPlayerFromId(src)
	for k, Player in pairs(Players) do
		TriggerClientEvent('unr3al_methvan:client:blowup', Player.source, pos.x, pos.y, pos.z, entity, netId)
	end
	TriggerEvent('unr3al_methvan:server:stopProduction', src, netId)
	Player.removeInventoryItem(Config.Items.Methlab, 1)

	if Config.LogType == 'discord' then
		DiscordLogs("explosion", "Explosion", "red", {
			{name = "Player Informations", value = " ", inline = false},
			{name = "ID", value = src, inline = true},
			{name = "Name", value = xPlayer.name, inline = true},
			{name = "Identifier", value = xPlayer.identifier, inline = true},
			{name = " ", value = " ", inline = false},
			{name = "Cords", value = " ", inline = false},
			{name = "X", value = tostring(posx), inline = true},
			{name = "Y", value = tostring(posy), inline = true},
			{name = "Z", value = tostring(posz), inline = true},
		})
	elseif Config.LogType == 'ox_lib' then
		lib.logger(xPlayer.identifier, 'Meth Explosion', 'A Meth Van Exploded at: '..tostring(pos))
	elseif Config.LogType == 'disabled' then
	else
		print("MISSING LOG TYPE")
	end
end)

---gives out the meth after finishing production
---@param source any
---@param methAmount any
---@param netId any
local function finishProduction(source, methAmount, netId)
	local src = source
	local Player = ESX.GetPlayerFromId(src)

	if Config.Debug then print('Base Quality: '.. methMakers[src].quality) end

	local rnd = math.random(Config.Items[methMakers[src].methType].Meth.Chance.Min, Config.Items[methMakers[src].methType].Meth.Chance.Max)
	local Amount = math.floor(methAmount / 2) + rnd
	if Config.Debug then print('Base Amount: '.. Amount) end
	local MethAmount = Amount

	if Player.canCarryItem(Config.Items[methMakers[src].methType].Meth.ItemName, MethAmount) or Config.Inventory.ForceAdd then
		Player.addInventoryItem(Config.Items[methMakers[src].methType].Meth.ItemName, MethAmount)
	elseif invstate == 'started' then
		local AmountPlayerCanCarry = exports.ox_inventory:CanCarryAmount(src, Config.Items[methMakers[src].methType].Meth.ItemName)
		if (AmountPlayerCanCarry <= 0) then
			AmountPlayerCanCarry = 0
		end
		if Config.Debug then print('Space for Meth: '.. AmountPlayerCanCarry) end

		if Config.Inventory.oxSplit and not AmountPlayerCanCarry == 0 then
			if Amount <= AmountPlayerCanCarry then
				MethAmount = Amount
			else
				MethAmount = AmountPlayerCanCarry
			end
			Player.addInventoryItem(Config.Items[methMakers[src].methType].Meth.ItemName, MethAmount)
		end
	end

	if Config.Debug then print('Amount added: '.. MethAmount) end
	local pos = GetEntityCoords(GetPlayerPed(src))

	if Config.LogType == 'discord' then
		DiscordLogs("finish", "Finished Cooking", "green", {

			{name = "Player Informations", value = " ", inline = false},
			{name = "ID", value = tostring(src), inline = true},
			{name = "Name", value = tostring(Player.name), inline = true},
			{name = "Identifier", value = tostring(Player.identifier), inline = true},
			{name = " ", value = " ", inline = false},
			{name = "Meth", value = " ", inline = false},
			{name = "Amount", value = tostring(MethAmount), inline = true},
			{name = " ", value = " ", inline = false},
			{name = "Cords", value = " ", inline = false},
			{name = "X", value = tostring(pos.x), inline = true},
			{name = "Y", value = tostring(pos.y), inline = true},
			{name = "Z", value = tostring(pos.z), inline = true},
		})
	elseif Config.LogType == 'ox_lib' then
		lib.logger(xPlayer.identifier, 'Finished Cooking Meth', 'Meth Player Got: '..MethAmount)
	elseif Config.LogType == 'disabled' then
	else
		print("MISSING LOG TYPE")
	end
	TriggerEvent('unr3al_methvan:server:stopProduction', src, netId)
end

---Production loop
---@param source string
---@param netId integer
RegisterNetEvent('unr3al_methvan:server:production', function(source, netId)
	local src = source
	local entity = NetworkGetEntityFromNetworkId(netId)
	local ped = GetPlayerPed(src)

	if Config.Debug then print(methMakers[src]) end

	while (methMakers[src]) do
		Wait(10)
		if Config.Debug then print('Entity Model: '..GetEntityModel(entity)) end
		if (DoesEntityExist(entity) and GetEntityModel(methMakers[src].vehicle) == `journey`) and GetVehiclePedIsIn(ped, false) ~= 0 then
			TriggerEvent('unr3al_methvan:server:smoke', source, netId)
			if (not methMakers[src].paused) then
				methMakers[src].quality += 1
				TriggerClientEvent('unr3al_methvan:client:notify', src, Config.Noti.info, Locales[Config.Locale]['Update1'] .. methMakers[src].progress .. Locales[Config.Locale]['Update2'])
			end
		else
			if Config.Debug then print('Stopped because not in vehicle') end
			TriggerEvent('unr3al_methvan:server:stopProduction', src, netId)
			return
		end
		if (methMakers[src].progress < 95) then
			Citizen.Wait(Config.PauseTime)
			if Config.Debug then print('Paused state: '..tostring(methMakers[src].paused)) end
			if not methMakers[src].paused and GetVehiclePedIsIn(ped, false) ~= 0 then
				

				local Percent = math.random(Config.Progress.Min, Config.Progress.Max)
				methMakers[src].progress += Percent
				MiniGamePercentage = math.random(1, Config.ChangeMiniGame)
				if Config.Debug then print("Minigame Chance: "..MiniGamePercentage) end
			end
			if (not methMakers[src].paused and methMakers[src].progress > 10 and methMakers[src].progress < 95 and MiniGamePercentage == 1 and methMakers[src]) then
				methMakers[src].paused = true
				local MiniGame = math.random(1,8)
				local tempquality = lib.callback.await('unr3al_methvan:client:openContext', src, MiniGame, netId)
				if methMakers[src] ~= nil then
					methMakers[src].quality = methMakers[src].quality + tempquality
					methMakers[src].paused = false
				end
			end
		else
			TriggerClientEvent('unr3al_methvan:client:notify', src, Config.Noti.success, Locales[Config.Locale]['Production_Finish'], Config.Noti.time)

			if Config.Debug then print('Quality: '..methMakers[src].quality) end
			finishProduction(source, methMakers[src].quality, netId)
			return
		end
	end
end)

---Syncs smoke for all clients
---@param source string
---@param netId integer
RegisterServerEvent('unr3al_methvan:server:smoke', function(source, netId)
	local src = source
	local Player = ESX.GetPlayerFromId(src)
	local entity = NetworkGetEntityFromNetworkId(netId)
	local pos = GetEntityCoords(entity)

    if not methMakers[src] or not DoesEntityExist(entity) then
        return
    end
	
	if Player.getInventoryItem(Config.Items.Methlab).count >= 1 then
		local Players = ESX.GetExtendedPlayers()

		for k, Player in pairs(Players) do
			TriggerClientEvent('unr3al_methvan:client:smoke', Player.source, false, netId)
		end
	else
		methMakers[src] = nil
		TriggerEvent('unr3al_methvan:server:stopProduction', src, netId)
	end
end)


if Config.LogType == 'discord' then
	function DiscordLogs(name, title, color, fields)
		local webHook = Config.DiscordLogs.Webhooks[name]
		if not webHook == 'WEEBHOCKED' then
			local embedData = {{
				['title'] = title,
				['color'] = Config.DiscordLogs.Colors[color],
				['footer'] = {
					['text'] = "| Unr3al Meth | " .. os.date(),
					['icon_url'] = "https://cdn.discordapp.com/attachments/1091344078924435456/1091458999020425349/OSaft-Logo.png"
				},
				['fields'] = fields,
				['author'] = {
					['name'] = "Meth Car",
					['icon_url'] = "https://cdn.discordapp.com/attachments/1091344078924435456/1091458999020425349/OSaft-Logo.png"
				}
			}}
			PerformHttpRequest(webHook, nil, 'POST', json.encode({
				embeds = embedData
			}), {
				['Content-Type'] = 'application/json'
			})
		end
	end
end