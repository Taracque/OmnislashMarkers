local frame, events = CreateFrame("Frame"), {};
local listOfPlayers = {}

function events:PLAYER_ENTERING_WORLD(...)
	print("OmnislashMarkers Loaded - requires raid assist!")
end

function events:PLAYER_REGEN_ENABLED(...)
	local i,v
	for i,v in pairs(listOfPlayers) do
		SetRaidTargetIcon(i, 0)
	end
	listOfPlayers = {}
end

function events:COMBAT_LOG_EVENT_UNFILTERED(self, event, ...)
 	local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...; -- Those arguments appear for all combat event variants.

	playerWithBuff = select(7, ...)
	buffName = select(11, ...)

	if buffName == "Disrupting Shadows" and event == "SPELL_AURA_APPLIED" then

		local i
		local name
		local party
		local icon
		local icon1 = 1
		local icon2 = 4
		
		for i=1,MAX_RAID_MEMBERS,1 do
			name, _,party = GetRaidRosterInfo(i);
			if (name == playerWithBuff) then
				
				break
			end
			party = 0
		end

		if (party ~= 0) then
			for i,v in pairs(listOfPlayers) do
				if ((v >= icon1) and (v<4)) then
					icon1 = v+1
				end
				if (v >= icon2) then
					icon2 = v+1
				end
			end
			if (party == 1) then
				icon = icon1
			else
				icon = icon2
			end

			SetRaidTargetIcon(destGUID, icon)
			SendChatMessage( buffName .. " on " .. playerWithBuff .. "{rt" .. icon .. "}", "RAID_WARNING" )
			listOfPlayers[destGUID] = icon
		end
	end	
	if buffName == "Disrupting Shadows" and event == "SPELL_AURA_REMOVED" then
		SetRaidTargetIcon(destGUID, 0)
		SendChatMessage( buffName .. " faded from " .. playerWithBuff, "RAID" )
		listOfPlayers[destGUID] = 0
	end
	if (sourceName == "Void of the Unmaking") then
		icon = GetRaidTargetIndex(sourceGUID)
		if (icon ~= 8) then
			SetRaidTargetIcon(destGUID, 8)
			SendChatMessage( sourceName .. " {rt8}", "RAID" )
		end
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...); -- call one of the functions above
end);

for k, v in pairs(events) do
	frame:RegisterEvent(k); -- Register all events for which handlers have been defined
end