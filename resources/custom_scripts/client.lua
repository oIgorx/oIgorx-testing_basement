local noclip = false
local handcuff = false

function yum_getCamDirection()
	local heading = GetGameplayCamRelativeHeading()+GetEntityHeading(GetPlayerPed(-1))
	local pitch = GetGameplayCamRelativePitch()
	local x = -math.sin(heading*math.pi/180.0)
	local y = math.cos(heading*math.pi/180.0)
	local z = math.sin(pitch*math.pi/180.0)
	local len = math.sqrt(x*x+y*y+z*z)
	if len ~= 0 then
		x = x / len
		y = y / len
		z = z / len
	end
	return x,y,z
end

function yum_Split(str, pat)
	local t = {} -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t, cap)
		end
		last_end = e + 1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

function yum_noClip()
	noclip = not noclip
	local ped = PlayerPedId()
	if noclip then
		SetEntityInvincible(ped,true)
		SetEntityVisible(ped,false,false)
	else
		SetEntityInvincible(ped,false)
		SetEntityVisible(ped,true,false)
	end
end

RegisterCommand("tpcds", function(source,args)
    local result = yum_Split(args[1],",")
    SetEntityCoordsNoOffset(PlayerPedId(), tonumber(result[1]),tonumber(result[2]),tonumber(result[3]), 0, 0, 0)
end)

RegisterCommand("nc", function(source,args)
    yum_noClip()
end)

RegisterCommand("cds", function(source,args)
	local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1)))
	local h = GetEntityHeading(GetPlayerPed(-1))
    TriggerServerEvent("sendCDS",x,y,z,h)
end)

RegisterCommand("tpway",function(source,args)
    local ped = PlayerPedId()
	local veh = GetVehiclePedIsUsing(ped)
	if IsPedInAnyVehicle(ped) then
		ped = veh
    end

	local waypointBlip = GetFirstBlipInfoId(8)
	local x,y,z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09,waypointBlip,Citizen.ResultAsVector()))

	local ground
	local groundFound = false
	local groundCheckHeights = { 0.0,50.0,100.0,150.0,200.0,250.0,300.0,350.0,400.0,450.0,500.0,550.0,600.0,650.0,700.0,750.0,800.0,850.0,900.0,950.0,1000.0,1050.0,1100.0 }

	for i,height in ipairs(groundCheckHeights) do
		SetEntityCoordsNoOffset(ped,x,y,height,0,0,1)

		RequestCollisionAtCoord(x,y,z)
		while not HasCollisionLoadedAroundEntity(ped) do
			RequestCollisionAtCoord(x,y,z)
			Citizen.Wait(1)
		end
		Citizen.Wait(20)

		ground,z = GetGroundZFor_3dCoord(x,y,height)
		if ground then
			z = z + 1.0
			groundFound = true
			break;
		end
	end

	if not groundFound then
		z = 1200
		GiveDelayedWeaponToPed(PlayerPedId(),0xFBAB5776,1,0)
	end

	RequestCollisionAtCoord(x,y,z)
	while not HasCollisionLoadedAroundEntity(ped) do
		RequestCollisionAtCoord(x,y,z)
		Citizen.Wait(1)
	end
	SetEntityCoordsNoOffset(ped,x,y,z,0,0,1)
end)

Citizen.CreateThread(function()
	while true do
		local msec = 1000
		if noclip then
			msec = 4
			local ped = PlayerPedId()
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local dx,dy,dz = yum_getCamDirection()
			local speed = 1.0

			SetEntityVelocity(ped,0.0001,0.0001,0.0001)

			if IsControlPressed(1,21) then
				speed = 5.0
			end

			if IsControlPressed(1,32) then
				x = x+speed*dx
				y = y+speed*dy
				z = z+speed*dz
			end

			if IsControlPressed(1,269) then
				x = x-speed*dx
				y = y-speed*dy
				z = z-speed*dz
			end
			SetEntityCoordsNoOffset(ped,x,y,z,true,true,true)
		end
		Citizen.Wait(msec)
	end
end)

RegisterCommand('car',function(_,args)
    local mhash = GetHashKey(args[1])
    while not HasModelLoaded(mhash) do
        RequestModel(mhash)
        Citizen.Wait(10)
    end

    if HasModelLoaded(mhash) then
        local ped = PlayerPedId()
        local nveh = CreateVehicle(mhash,GetEntityCoords(ped),GetEntityHeading(ped),true,false)

        SetVehicleOnGroundProperly(nveh)
        SetVehicleNumberPlateText(nveh,vRP.getRegistrationNumber())
        SetEntityAsMissionEntity(nveh,true,true)
        TaskWarpPedIntoVehicle(ped,nveh,-1)
        SetModelAsNoLongerNeeded(mhash)
    end
end)

RegisterCommand('fix', function()
    local v = GetVehiclePedIsIn(PlayerPedId())
    local fuel = GetVehicleFuelLevel(v)
    SetVehicleFixed(v)
    SetVehicleDirtLevel(v,0.0)
    SetVehicleUndriveable(v,false)
    SetEntityAsMissionEntity(v,true,true)
    SetVehicleOnGroundProperly(v)
    SetVehicleFuelLevel(v,fuel)
end)

RegisterCommand('tuning',function()
	local vehicle = GetVehiclePedIsIn(PlayerPedId())
	SetVehicleModKit(vehicle,0)
	SetVehicleWheelType(vehicle,7)
	SetVehicleMod(vehicle,0,GetNumVehicleMods(vehicle,0)-1,false)
	SetVehicleMod(vehicle,1,GetNumVehicleMods(vehicle,1)-1,false)
	SetVehicleMod(vehicle,2,GetNumVehicleMods(vehicle,2)-1,false)
	SetVehicleMod(vehicle,3,GetNumVehicleMods(vehicle,3)-1,false)
	SetVehicleMod(vehicle,4,GetNumVehicleMods(vehicle,4)-1,false)
	SetVehicleMod(vehicle,5,GetNumVehicleMods(vehicle,5)-1,false)
	SetVehicleMod(vehicle,6,GetNumVehicleMods(vehicle,6)-1,false)
	SetVehicleMod(vehicle,7,GetNumVehicleMods(vehicle,7)-1,false)
	SetVehicleMod(vehicle,8,GetNumVehicleMods(vehicle,8)-1,false)
	SetVehicleMod(vehicle,9,GetNumVehicleMods(vehicle,9)-1,false)
	SetVehicleMod(vehicle,10,GetNumVehicleMods(vehicle,10)-1,false)
	SetVehicleMod(vehicle,11,GetNumVehicleMods(vehicle,11)-1,false)
	SetVehicleMod(vehicle,12,GetNumVehicleMods(vehicle,12)-1,false)
	SetVehicleMod(vehicle,13,GetNumVehicleMods(vehicle,13)-1,false)
	SetVehicleMod(vehicle,14,16,false)
	SetVehicleMod(vehicle,15,GetNumVehicleMods(vehicle,15)-2,false)
	SetVehicleMod(vehicle,16,GetNumVehicleMods(vehicle,16)-1,false)
	ToggleVehicleMod(vehicle,17,true)
	ToggleVehicleMod(vehicle,18,true)
	ToggleVehicleMod(vehicle,19,true)
	ToggleVehicleMod(vehicle,20,true)
	ToggleVehicleMod(vehicle,21,true)
	ToggleVehicleMod(vehicle,22,true)
	SetVehicleMod(vehicle,23,1,false)
	SetVehicleMod(vehicle,24,1,false)
	SetVehicleMod(vehicle,25,GetNumVehicleMods(vehicle,25)-1,false)
	SetVehicleMod(vehicle,27,GetNumVehicleMods(vehicle,27)-1,false)
	SetVehicleMod(vehicle,28,GetNumVehicleMods(vehicle,28)-1,false)
	SetVehicleMod(vehicle,30,GetNumVehicleMods(vehicle,30)-1,false)
	SetVehicleMod(vehicle,33,GetNumVehicleMods(vehicle,33)-1,false)
	SetVehicleMod(vehicle,34,GetNumVehicleMods(vehicle,34)-1,false)
	SetVehicleMod(vehicle,35,GetNumVehicleMods(vehicle,35)-1,false)
	SetVehicleMod(vehicle,38,GetNumVehicleMods(vehicle,38)-1,true)
	SetVehicleTyreSmokeColor(vehicle,0,0,127)
	SetVehicleWindowTint(vehicle,1)
	SetVehicleTyresCanBurst(vehicle,false)
	SetVehicleNumberPlateText(vehicle,"YUME")
	SetVehicleNumberPlateTextIndex(vehicle,5)
	SetVehicleModColor_1(vehicle,4,12,0)
	SetVehicleModColor_2(vehicle,4,12)
	SetVehicleColours(vehicle,12,12)
	SetVehicleExtraColours(vehicle,70,141)
end)