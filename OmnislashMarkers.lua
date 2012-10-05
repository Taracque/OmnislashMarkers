local frame, events = CreateFrame("Frame"), {};
local listOfPlayers = {}
local icon = 0
local enabled = false
local heroic = false
local instanceName = ""
local encounter = ""
local do_mark = 0
local waitTable = {}
local waitFrame = nil

function events:PLAYER_ENTERING_WORLD(...)
	print("OmnislashMarkers Loaded")
	OM_DetectInstance()
end

function events:RAID_INSTANCE_WELCOME(...)
	OM_DetectInstance()
end

function events:PLAYER_REGEN_DISABLED(...)
	OM_DetectEncounter()
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

function OM_DetectInstance()
	local iname, itype, idifficulty, idifficultyName, isize = GetInstanceInfo()
	if (isize and ( isize >= 10) and ( itype == "raid" )) then
		print("OmnislashMarkers - Enabled, requires raid assist!")
		if (
			(idifficultyName == "10 Player (Heroic)") or
			(idifficultyName == "25 Player (Heroic)")
		) then
			heroic = true
		else
			heroic = false
		end
		instanceName = iname
		enabled = true
	else
		print("OmnislashMarkers - Disabled (not in raid)")
		enabled = false
		heroic = false
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

function OM_DetectEncounter()
	print("OmnislashMarkers - Detecting encounter")
	-- Mogu'shan Vaults boss IDS:  Cobalt: 60051 Jade: 60043 Jasper: 59915

	encounter = ""
end

function OM_hasDeBuff(unit, spellName, casterUnit)
	local i = 1;
	while true do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitDebuff(unit, i);
		if not name then
			break;
		end
		if (name) and (spellName) then
			if string.match(name, spellName) and ((unitCaster == casterUnit) or (casterUnit == nil)) then
				return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable;
			end
		end
		i = i + 1;
	end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(self, event, ...)
 	local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...; -- Those arguments appear for all combat event variants.
	local i

	if enabled then
		if (encounter ~= "") then
			playerWithBuff = select(7, ...)
			buffName = select(11, ...)
	
			-- MoP raids
			-- Mogu'shan Vaults
			if (encounter == "The Stone Guard") then
			
			
			end
		
		end
	end
end

frame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...); -- call one of the functions above
end);

for k, v in pairs(events) do
	frame:RegisterEvent(k); -- Register all events for which handlers have been defined
end