local frame, events = CreateFrame("Frame"), {};
local listOfPlayers = {}
local hour_of_twilight_count = 0
local hot_standers = {
	[1] = {
		[1] = "Zedicus",
		[2] = "Adorján",
		[3] = ""
	},
	[2] = {
		[1] = "Meitra",
		[2] = "Misztermakáj",
		[3] = ""
	},
	[3] = {
		[1] = "Dögrovás",
		[2] = "Holywing",
		[3] = "Divine protection"
	},
	[4] = {
		[1] = "Zedicus",
		[2] = "Adorján",
		[3] = ""
	},
	[5] = {
		[1] = "Meitra",
		[2] = "Misztermakáj",
		[3] = ""
	},
	[6] = {
		[1] = "Dögrovás",
		[2] = "Holywing",
		[3] = "Divine protection"
	},
	[7] = {
		[1] = "Zedicus",
		[2] = "Adorján",
		[3] = ""
	}
}
local globule_priority = {
	[105420] = {	-- purple - green - blue - BLACK
		["marking"] = "Dark Globule",
		["warning"] = "{rt5} Fekete! {rt5} Direkt heal stop, spread, Mana Void"
	},
	[105435] = {	-- GREEN - red - black - blue
		["marking"] = "Acidic Globule",
		["warning"] = "{rt4} Zöld! {rt4} Össze, AoE, Mana Void"
	},
	[105436] = {	-- green - YELLOW - red - black
		["marking"] = "Glowing Globule",
		["warning"] = "{rt1} Sárga! {rt1} Spread (minimálisan), AoE"
	},
	[105437] = {	-- blue - purple - YELLOW - green
		["marking"] = "Glowing Globule",
		["warning"] = "{rt1} Sárga! {rt1} Direkt heal stop, spread, Mana Void"
	},
	[105439] = {	-- blue - black - YELLOW - purple
		["marking"] = "Glowing Globule",
		["warning"] = "{rt1} Sárga! {rt1} Direkt heal stop, AoE, Mana Void"
	},
	[105440] = {	-- purple - red - black - YELLOW
		["marking"] = "Glowing Globule",
		["warning"] = "{rt1} Sárga! {rt1} Direkt heal stop, Össze, AoE"
	},
	[105441] = {	-- ???
		["marking"] = "",
		["warning"] = "Ismeretlen kombináció... csak éld túl"
	}
}
local icon = 0
local enabled = false
local do_mark = 0
local waitTable = {}
local waitFrame = nil

function events:PLAYER_ENTERING_WORLD(...)
	if ( GetInstanceDifficulty() >= 3) then
		enabled = true
	else
		print("OmnislashMarkers Loaded, but disabled (non Heroic Raid mode detected)")
		enabled = false
	end
end

function events:RAID_INSTANCE_WELCOME(...)
	if ( GetInstanceDifficulty() >= 3) then
		print("OmnislashMarkers Loaded - Enabled, requires raid assist!")
		enabled = true
	else
		print("OmnislashMarkers Loaded - Disabled (non Heroic Raid mode detected)")
		enabled = false
	end
end

function events:PLAYER_REGEN_ENABLED(...)
	local i,v
	for i,v in pairs(listOfPlayers) do
		SetRaidTargetIcon(i, 0)
	end
	listOfPlayers = {}
end

function events:UNIT_SPELLCAST_SUCCEEDED(event, ...)
	if enabled then
		local spellID = select(5, ...)
		-- Yor'sahj HC
		if globule_priority[spellID] then
			SendChatMessage( globule_priority[spellID]["warning"], "RAID_WARNING" )
			do_mark = spellID
		end
	end
end

function OM_wait(delay, func, ...)
	if(type(delay) ~= "number" or type(func) ~= "function") then
		return false
	end
	if not waitFrame then
		waitFrame = CreateFrame("Frame", nil, UIParent)
		waitFrame:SetScript("OnUpdate", function (self, elapse)
			local count = #waitTable;
			local i = 1;
			while(i<=count) do
				local waitRecord = tremove(waitTable, i)
				local d = tremove(waitRecord, 1)
				local f = tremove(waitRecord, 1)
				local p = tremove(waitRecord, 1)
				if d > elapse then
					tinsert(waitTable, i, {d - elapse, f, p})
					i = i + 1
				else
					count = count - 1
					f(unpack(p))
				end
			end
		end)
	end
	tinsert(waitTable, {delay, func, {...}})
	return true
end

function OM_ULTRAXION_displayWarning(counter)
	local i

	if (hot_standers[counter]) then
		for i=1, 2 do
			if (hot_standers[counter][i]) and (listOfPlayers[ hot_standers[counter][i] ]) then
				SetRaidTarget( listOfPlayers[ hot_standers[counter][i] ], 6 + i)
			end
		end
		if (hot_standers[counter][3] ~= "") then
			SendChatMessage( hot_standers[counter][1] .. ", " .. hot_standers[counter][2] .. " " .. hot_standers[counter][3] , "RAID_WARNING" )
		end
	end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(self, event, ...)
 	local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...; -- Those arguments appear for all combat event variants.
	local i

	if enabled then
		playerWithBuff = select(7, ...)
		buffName = select(11, ...)
	
		-- Zon'ozz HC
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
				listOfPlayers[ UnitName("raid"..i) ] = "raid"..i
			end
	
			SendChatMessage( "Omnislash Markers - Ultraxion HC module loaded", "RAID" )
		end
		
		if buffName == "Hour of Twilight" then -- skull and cross
			if event == "SPELL_CAST_START" then
				hour_of_twilight_count = hour_of_twilight_count + 1
				OM_ULTRAXION_displayWarning( hour_of_twilight_count )
				OM_wait(40,OM_ULTRAXION_displayWarning,(hour_of_twilight_count+1))
			end
			if event == "SPELL_CAST_SUCCESS" then
				for i=1, 2 do
					SetRaidTarget( listOfPlayers[ hot_standers[hour_of_twilight_count][i] ], 0)
				end
			end
		end
		if buffName == "Fading Light" and event == "SPELL_AURA_APPLIED" then
			icon = icon + 1
			SetRaidTarget(destGUID, icon)
			if (icon >= 3) then
				icon = 0
			end
		end
		if buffName == "Fading Light" and event == "SPELL_AURA_REMOVED" then
			SetRaidTarget(destGUID, 0)
		end
		
		-- Yor'sahj HC Globule Marking
		if (do_mark ~= 0) then
			if (playerWithBuff) and (playerWithBuff == globule_priority[do_mark]["marking"]) then
				SetRaidTarget(destGUID, 7) -- Skull
				SendChatMessage( globule_priority[do_mark]["warning"], "RAID_WARNING" )
				do_mark = 0
			end
		end
		
		-- Warmaster Blackhorn
		if playerWithBuff == "Twilight Sapper" then
			-- SendChatMessage( "Twilight Sapper {rt8}", "RAID_WARNING" )
			SetRaidTarget(destGUID, 8)
		end
		if buffName == "Twilight Barrage" and event == "SPELL_AURA_APPLIED" then
			icon = 1	
			
			for i,v in pairs(listOfPlayers) do
				if (v >= icon) then
					icon = v+1
				end
			end

			SetRaidTargetIcon(destGUID, icon)
			SendChatMessage( buffName .. " on " .. playerWithBuff .. "{rt" .. icon .. "}", "RAID_WARNING" )
			listOfPlayers[destGUID] = icon
		end
		if buffName == "Twilight Barrage" and event == "SPELL_AURA_REMOVED" then
			SetRaidTargetIcon(destGUID, 0)
			SendChatMessage( buffName .. " faded from " .. playerWithBuff, "RAID" )
			listOfPlayers[destGUID] = 0
		end
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...); -- call one of the functions above
end);

for k, v in pairs(events) do
	frame:RegisterEvent(k); -- Register all events for which handlers have been defined
end