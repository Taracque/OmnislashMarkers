local frame, events = CreateFrame("Frame"), {};
local listOfPlayers = {}
local hour_of_twilight_count = 0
local hot_standers = {
	1 = {
		1 = "Dögrovás",
		2 = "Airween",
		3 = ""
	},
	2 = {
		1 = "Zedicus",
		2 = "Holywing",
		3 = "Divine protection!"
	},
	3 = {
		1 = "Meitra",
		2 = "Nashmabb",
		3 = "Pain Supression, Hand of Sacrifice"
	},
	4 = {
		1 = "Dögrovás",
		2 = "Airween",
		3 = ""
	},
	5 = {
		1 = "Zedicus",
		2 = "Classrun",
		3 = "Hand of Sacrifice"
	},
	6 = {
		1 = "Meitra",
		2 = "Holywing",
		3 = "Divine Shield"
	},
	7 = {
		1 = "Dögrovás",
		2 = "Airween",
		3 = ""
	}
}

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
	local i
	local icon

	-- Zon'ozz HC
	playerWithBuff = select(7, ...)
	buffName = select(11, ...)

	if buffName == "Disrupting Shadows" and event == "SPELL_AURA_APPLIED" then

		local name
		local party
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
	
	-- Ultraxion HC
	if buffName == "Last Defender of Azeroth" then
		hour_of_twilight_count = 0
		icon = 0
		-- load player's guid
		listOfPlayers = {}
		for i=1, GetNumRaidMembers() do
			listOfPlayers[ UnitName("raid"..i) ] = UnitGUID("raid"..i)
		end
	end if
	
	if buffName == "Hour of Twilight" then -- skull and cross
		hour_of_twilight_count = hour_of_twilight_count + 1
		for i=1, 2 do
			SetRaidTargetIcon( listOfPlayers[ hot_standers[hour_of_twilight_count][i] ], 6 + i)
		end
		if (hot_standers[hour_of_twilight_count][3] ~= "") then
			SendChatMessage( hot_standers[hour_of_twilight_count][3] , "RAID_WARNING" )
		end
	end if
	if buffName == "Fading Light" and event == "SPELL_AURA_APPLIED" then
		icon = icon + 1
		SetRaidTargetIcon(destGUID, icon)
		if (icon >= 3) then
			icon = 0
		end
	end
	if buffName == "Fading Light" and event == "SPELL_AURA_REMOVED" then
		SetRaidTargetIcon(destGUID, 0)
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...); -- call one of the functions above
end);

for k, v in pairs(events) do
	frame:RegisterEvent(k); -- Register all events for which handlers have been defined
end