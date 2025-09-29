-- HolyHealer Addon
-- Combines Flash of Light, Holy Light, Holy Shock, and Holy Strike functions into one script.
-- Extend by Drokin

-- Create a frame to handle events
local HolyHealerFrame = CreateFrame("Frame");

-- Global variables to store spell indices
local HOLY_SHOCK_INDEX = nil;
local CRUSADER_STRIKE_INDEX = nil;

-- Configuration for buffs
local REQUIRED_BUFF_ICON = 51309; -- Icon for Holy Judgement buff
local SEAL_OF_WISDOM_ICON = 51746; -- Icon for Seal of Wisdom

-- Debug variable, default to off
local DEBUG_MODE = false;

-- Debug function to print messages if debug mode is on
local function DebugPrint(message)
    if DEBUG_MODE then
        DEFAULT_CHAT_FRAME:AddMessage("HH DEBUG: " .. message);
    end
end

-- Register the ADDON_LOADED event
HolyHealerFrame:RegisterEvent("ADDON_LOADED");

-- Set up the event handler
HolyHealerFrame:SetScript("OnEvent", function()
    if event then
        --if event == "ADDON_LOADED" and arg1 == "HolyHealer" then
        DebugPrint(arg1);
        DebugPrint("event triggered");
        -- Function to cache spell indices when the addon loads
        local function CacheSpellIndices()
            local numSpells = GetNumSpellTabs();
            for tabIndex = 1, numSpells do
                local _, _, offset, numSpellsInTab = GetSpellTabInfo(tabIndex);
                for spellIndex = offset + 1, offset + numSpellsInTab do
                    local name = GetSpellName(spellIndex, BOOKTYPE_SPELL);
                    if name == "Holy Shock" then
                        HOLY_SHOCK_INDEX = spellIndex;
                    elseif name == "Crusader Strike" then
                        CRUSADER_STRIKE_INDEX = spellIndex;
                    end
                    if HOLY_SHOCK_INDEX and CRUSADER_STRIKE_INDEX then break; end
                end
                if HOLY_SHOCK_INDEX and CRUSADER_STRIKE_INDEX then break; end
            end

            -- Debug messages for addon load and spellbook check
            DebugPrint("HolyHealer addon has loaded successfully.");

            if HOLY_SHOCK_INDEX then
                DebugPrint("Holy Shock found in spellbook.");
            else
                DebugPrint("Holy Shock not found in spellbook.");
            end

            if CRUSADER_STRIKE_INDEX then
                DebugPrint("Crusader Strike found in spellbook.");
            else
                DebugPrint("Crusader Strike not found in spellbook.");
            end
        end

        -- Call this function when the addon loads
        CacheSpellIndices();
        --end
    end
end);

-- Utility Functions

-- Checks if a unit is valid, friendly, alive, and connected
local function IsHealable(unit)
    return UnitExists(unit) and UnitIsFriend("player", unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit);
end

-- Checks if a unit has a specific buff by its icon
local function HasBuffWithIcon(unit, iconPath)
    local i = 1;
    while true do
        local name, _, icon = UnitBuff(unit, i);
        if not name then break; end -- No more buffs
        if icon == iconPath then return true; end
        i = i + 1;
    end
    return false;
end

-- Checks if a unit is within a given range using interact distance
local function IsWithinRange(unit, rangeType)
    return CheckInteractDistance(unit, rangeType);
end

-- Finds the lowest health unit below a health threshold in the group
local function GetLowestHealthUnit(healthThreshold, spellName, rangeType)
    local lowestUnit = nil;
    local lowestHealthPct = 100;

    -- Check raid members
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local unit = "raid" .. i;
            if IsHealable(unit) and (not spellName or IsSpellInRange(spellName, unit) == 1) then
                local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100;
                if healthPct < healthThreshold and healthPct < lowestHealthPct then
                    lowestUnit = unit;
                    lowestHealthPct = healthPct;
                end
            end
        end
    else
        -- Check player and party members
        local units = {"player"};
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(units, "party" .. i);
            end
        end

        for _, unit in ipairs(units) do
            if IsHealable(unit) and (not spellName or IsSpellInRange(spellName, unit) == 1) then
                local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100;
                if healthPct < healthThreshold and healthPct < lowestHealthPct then
                    lowestUnit = unit;
                    lowestHealthPct = healthPct;
                end
            end
        end
    end

    return lowestUnit, lowestHealthPct;
end

-- Counts the number of players below a health threshold within 10 yards
local function GetPlayersBelowHealthThresholdInRange(minHP)
    local count = 0;

    -- Check raid members
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local unit = "raid" .. i;
            if IsHealable(unit) and IsWithinRange(unit, 3) then -- 3 = 10 yards
                local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100;
                if healthPct <= minHP then
                    count = count + 1;
                end
            end
        end
    else
        -- Check player and party members
        local units = {"player"};
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(units, "party" .. i);
            end
        end

        for _, unit in ipairs(units) do
            if IsHealable(unit) and IsWithinRange(unit, 3) then
                local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100;
                if healthPct <= minHP then
                    count = count + 1;
                end
            end
        end
    end

    return count;
end

-- Function to cache spell indices when the addon loads
local function CacheSpellIndices()
    local numSpells = GetNumSpellTabs();
    for tabIndex = 1, numSpells do
        local _, _, offset, numSpellsInTab = GetSpellTabInfo(tabIndex);
        for spellIndex = offset + 1, offset + numSpellsInTab do
            local name = GetSpellName(spellIndex, BOOKTYPE_SPELL);
            if name == "Holy Shock" then
                HOLY_SHOCK_INDEX = spellIndex;
            elseif name == "Crusader Strike" then
                CRUSADER_STRIKE_INDEX = spellIndex;
            end
            if HOLY_SHOCK_INDEX and CRUSADER_STRIKE_INDEX then break; end
        end
        if HOLY_SHOCK_INDEX and CRUSADER_STRIKE_INDEX then break; end
    end
    if not HOLY_SHOCK_INDEX then DEFAULT_CHAT_FRAME:AddMessage("Holy Shock not found in spellbook."); end
    if not CRUSADER_STRIKE_INDEX then DEFAULT_CHAT_FRAME:AddMessage("Crusader Strike not found in spellbook."); end
end

-- Call this function when the addon loads
CacheSpellIndices();

-- Debug function to print messages if debug mode is on
local function DebugPrint(message)
    if DEBUG_MODE then
        DEFAULT_CHAT_FRAME:AddMessage("HH DEBUG: " .. message);
    end
end

-- Function to handle slash commands
local function HolyHealer_OnSlashCommand(arg)
    --local command, arg = strsplit(" ", msg);
    command = command and strlower(command) or nil;

    if command == "debug" then
        if arg == "on" then
            DEBUG_MODE = true;
            DEFAULT_CHAT_FRAME:AddMessage("HH: Debug mode is now ON.");
        elseif arg == "off" then
            DEBUG_MODE = false;
            DEFAULT_CHAT_FRAME:AddMessage("HH: Debug mode is now OFF.");
        else
            DEFAULT_CHAT_FRAME:AddMessage("HH: Usage: /hh debug <on/off>");
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("HH: Unknown command. Use /hh debug <on/off>");
    end
end

-- Register slash command
SLASH_HOLYHEALER1 = "/hh";
SlashCmdList["HOLYHEALER"] = HolyHealer_OnSlashCommand;

-- Ensure melee buffs (Seal of Wisdom and Holy Judgement) are active
function aMeleeBuffs()
    if not HasBuffWithIcon("player", SEAL_OF_WISDOM_ICON) then
        CastSpellByName("Seal of Wisdom", "player");
        DebugPrint("Seal of Wisdom --> player (No seal active)");
        return false;
    end
    if not HasBuffWithIcon("player", REQUIRED_BUFF_ICON) then
        if UnitExists("target") and not UnitIsDead("target") then
            CastSpellByName("Judgement", "target");
            DebugPrint("Judgement --> " .. UnitName("target") .. " (No Holy Judgement buff)");
            return false;
        end
        DebugPrint("Holy Light : no valid target for Judgement");
        return false;
    end
    return true;
end

-- Healing and Melee Functions

-- Heal with Flash of Light
function aHealWithFoL(healthThreshold)
    healthThreshold = healthThreshold or 90;
    local target = GetLowestHealthUnit(healthThreshold, "Flash of Light", 5); -- 5 = 40 yards
    if target then
        CastSpellByName("Flash of Light", target);
        DebugPrint("|cFFFFFF00Flash of Light --> " .. UnitName(target) .. "|r");
        return true;
    end
    --DebugPrint("Flash of Light : no target");
    return false;
end

-- Heal with Holy Light
function aHealWithHL(healthThreshold)
    healthThreshold = healthThreshold or 45;
    if not aMeleeBuffs() then
        return false;
    end
    local target = GetLowestHealthUnit(healthThreshold, "Holy Light"); -- 40 yards
    if target and HasBuffWithIcon("player", REQUIRED_BUFF_ICON) and UnitExists(target) and IsHealable(target) then
        CastSpellByName("Holy Light", target);
        DebugPrint("|cFFFFD700Holy Light --> " .. UnitName(target) .. "|r");
        return true;
    end
    DebugPrint("Holy Light : no valid target or missing buff");
    return false;
end

-- Heal with Holy Shock
function aHealWithHS(healthThreshold)
    healthThreshold = healthThreshold or 90;
    local target, healthPct = GetLowestHealthUnit(healthThreshold, "Holy Shock", 4); -- 4 = 20 yards

    if not HOLY_SHOCK_INDEX then
        DebugPrint("Holy Shock <> NOT FOUND");
        return false;
    end

    local start, duration, _ = GetSpellCooldown(HOLY_SHOCK_INDEX, BOOKTYPE_SPELL);
    if start == 0 or (GetTime() - start) >= duration then
        -- Holy Shock is off cooldown, cast it if there's a target
        if target then
            CastSpellByName("Holy Shock", target);
            DebugPrint("|cFFFF0000Holy Shock --> " .. UnitName(target) .. "|r");
            return true;
        else
            --DebugPrint("Holy Shock : threshold not met");
            return false;
        end
    else
        --DebugPrint("Holy Shock ... on cooldown.");
        return false;
    end
    return false;
end

-- Cast Holy Strike or Crusader Strike if Holy Strike conditions are not met
function aCastHolyStrike(HSminHP, HSminTargets)
    local playersInRange = GetPlayersBelowHealthThresholdInRange(HSminHP);
    if playersInRange >= HSminTargets then
        -- Check if the current target is within melee range (5 yards)
        if IsWithinRange("target", 1) and UnitAffectingCombat("player") and UnitAffectingCombat("target") then  -- 1 for melee range (5 yards)
            CastSpellByName("Holy Strike");
            DebugPrint("|cFF00FF00Holy Strike --> Players in range: " .. playersInRange .. "|r");
            return true;
        else
            --DebugPrint("Holy Strike : Target not in melee. Players in range: " .. playersInRange);
            return false;
        end
    else
        --DebugPrint("Holy Strike : conditions not met. Players in range: " .. playersInRange);
        -- Check if Holy Shock is on cooldown to decide casting Crusader Strike
        if HOLY_SHOCK_INDEX then
            local start, duration, _ = GetSpellCooldown(HOLY_SHOCK_INDEX, BOOKTYPE_SPELL);
            if start ~= 0 and (GetTime() - start) < duration then
                -- Holy Shock is on cooldown, attempt to cast Crusader Strike
                if CRUSADER_STRIKE_INDEX then
                    local startCS, durationCS, _ = GetSpellCooldown(CRUSADER_STRIKE_INDEX, BOOKTYPE_SPELL);
                    if startCS == 0 or (GetTime() - startCS) >= durationCS then
                        -- Check if the current target is within melee range (5 yards)
                        if IsWithinRange("target", 1) and UnitAffectingCombat("player") and UnitAffectingCombat("target") then  -- 1 for melee range (5 yards)
                            CastSpellByName("Crusader Strike", "target");
                            DebugPrint("|cFF90EE90Crusader Strike : resetting Holy Shock|r");
                            return true;
                        else
                            --DebugPrint("Crusader Strike : Target not in melee");
                            return false;
                        end
                    else
                        --DebugPrint("Crusader Strike ... on cooldown");
                        return false;
                    end
                else
                    DebugPrint("Crusader Strike <> not found");
                    return false;
                end
            else
                --DebugPrint("Crusader Strike : no need. Holy Shock off cooldown");
                return false;
            end
        else
            DebugPrint("Holy Shock <> not found");
            return false;
        end
    end
    return false;
end

function MasterHealSequence()
    --DebugPrint("----------------")
    
    if aHealWithHL(25) then return true end
    if aHealWithHS(90) then return true end
    if aCastHolyStrike(90, 4) then return true end
    if aHealWithHL(45) then return true end
    if aHealWithFoL(90) then return true end
    
    return false -- If none of the spells were cast
end
