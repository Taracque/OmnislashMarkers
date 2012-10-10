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
local activeDebuff = ""
local bosses = {}
local skullBoss = ""
local crossBoss = ""

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
	end
end

function OM_DetectInstance()
	local iname, itype, idifficulty, idifficultyName, isize = GetInstanceInfo()
	if (isize and ( isize >= 10) and ( itype == "raid" )) then
		if (
			(idifficultyName == "10 Player (Heroic)") or
			(idifficultyName == "25 Player (Heroic)")
		) then
			heroic = true
		else
			heroic = false
		end
		print("OmnislashMarkers - " .. iname .. " enabled, requires raid assist! ")
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
	-- print("OmnislashMarkers - Detecting encounter")
	-- Mogu'shan Vaults boss IDS:  Cobalt: 60051 Jade: 60043 Jasper: 59915
	if (UnitName("boss1")) then
		print("Boss: " .. UnitName("boss1") .. " detected")
	else
		encounter = ""
	end
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
-- 		timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, spellId, spellName, spellSchool, damage
function events:COMBAT_LOG_EVENT_UNFILTERED(self, event, ...)
	local i

	if enabled then
		playerWithBuff = select(7, ...)
		sourceName = select(3, ...)
		buffName = select(11, ...)
		sourceGUID = select(2, ...)
		
		if (encounter == "") then
			if (buffName == "Solid Stone") then
				encounter = "The Stone Guard"
				SendChatMessage( "OmnislashMarkers - " .. encounter .. " encounter detcted", "RAID" )
				
				for i=1, 4 do
					if (UnitHealth( "boss" .. i) > 0) then
						bosses[UnitName( "boss" .. i )] = "boss" .. i
					end
				end
			end
		else
			playerWithBuff = select(7, ...)
			buffName = select(11, ...)
	
			-- MoP raids
			-- Mogu'shan Vaults
			if (encounter == "The Stone Guard") then
				if (buffName == "Solid Stone") then
					bosses[sourceName] = sourceGUID
				end
				-- check wich guardian needs to be charged
				if (event == "SPELL_AURA_APPLIED") then
					if (
						((buffName == "Cobalt Petrification") and (activeDebuff ~= buffName)) or
						((buffName == "Jade Petrification") and (activeDebuff ~= buffName)) or
						((buffName == "Jasper Petrification") and (activeDebuff ~= buffName)) or
						((buffName == "Amethyst Petrification") and (activeDebuff ~= buffName))
					) then
						activeDebuff = buffName
						-- mark skull
						if (activeDebuff == "Cobalt Petrification") then
							skullBoss = "Cobalt Guardian"
						elseif (activeDebuff == "Jade Petrification") then
							skullBoss = "Jade Guardian"
						elseif (activeDebuff == "Jasper Petrification") then
							skullBoss = "Jasper Guardian"
						elseif (activeDebuff == "Amethyst Petrification") then
							skullBoss = "Amethyst Guardian"
						end
						if (bosses[skullBoss]) then
							SetRaidTarget(bosses[skullBoss], 8)
						end
						SendChatMessage( buffName .. " activated, kill {rt8}" .. skullBoss .. "{rt8}!!!", "RAID_WARNING" )
					end
				end
				-- check boss energies
				for i=1, 4 do
					local maxEnergy = 0
					local minEnergy = 1000
					local tmpName = UnitName( "boss" .. i )
					if (tmpName ~= skullBoss) then
						if (UnitHealth( "boss" .. i) > 0) then
							if (UnitPower( "boss" .. i ) > maxEnergy) then
								maxEnergy = "boss" .. i
							end
							if (UnitPower( "boss" .. i ) < minEnergy) then
								minEnergy = "boss" .. i
							end
						end
					end
					-- cross marked energy > 50 then change it to lower one
					if (crossBoss ~= "") and (UnitPower( crossBoss ) > 50) then
						SetRaidTarget( minEnergy, 7) -- cross
						SendChatMessage( "Taunt {rt7}" .. UnitName(minEnergy) .. "{rt7}!!!", "RAID_WARNING" )
					end
				end
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