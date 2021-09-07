function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end

RegisterNetEvent("sendCDS")
AddEventHandler("sendCDS",function(x,y,z,h)
    SendWebhookMessage(GetConvar('_discord_webhook','default'),"```\nx = "..x..",y = "..y..",z = "..z.."\nx = "..x..",y = "..y..",z = "..z..",h = "..h.."\n"..x..","..y..","..z.."\n"..x..","..y..","..z..","..h.."\n['x'] = "..x..", ['y'] = "..y..", ['z'] = "..z..", ['h'] = "..h.."```")
end)