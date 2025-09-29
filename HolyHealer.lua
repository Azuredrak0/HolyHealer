-- HolyHealer Addon
-- Combines Flash of Light, Holy Light, Holy Shock, Holy Strike, and Aura management functions into one script.
-- Extend by Drokin

-- Create a frame to handle events
HolyHealerFrame = CreateFrame("Frame");

-- Global variables to store spell indices
HOLY_SHOCK_INDEX = nil;
CRUSADER_STRIKE_INDEX = nil;

-- Configuration for buffs
REQUIRED_BUFF_ICON = 51309; -- Icon for Holy Judgement buff
SEAL_OF_WISDOM_ICON = 51746; -- Icon for Seal of Wisdom

-- Configuration for auras (priority list)
AURA_PRIORITY = {
    {name = "Concentration Aura", icon = 19746},
    {name = "Sanctity Aura", icon = 20218},
    {name = "Devotion Aura", icon = 10293},
    {name = "Retribution Aura", icon = 10301},
    {name = "Frost Resistance Aura", icon = 19898},
    {name = "Fire Resistance Aura", icon = 19900},
    {name = "Shadow Resistance Aura", icon = 19896}
};

-- Debug variable, default to off
DEBUG_MODE = false;

-- Debug function to print messages if debug mode is on
function DebugPrint(message)
    if DEBUG_MODE then
        DEFAULT_CHAT_FRAME:AddMessage("HH DEBUG: " .. message);
    end
end

-- Register the ADDON_LOADED event
HolyHealerFrame:RegisterEvent("ADDON_LOADED");

-- Set up the event handler
HolyHealerFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "HolyHealer" then
        DebugPrint("HolyHealer addon loaded successfully.");
        CacheSpellIndices();
    end
end);

-- Function to cache spell indices when the addon loads
function CacheSpellIndices()
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

-- Utility Functions

-- Checks if a unit is valid, friendly, alive, and connected
function IsHealable(unit)
    return UnitExists(unit) and UnitIsFriend("player", unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit);
end

-- Checks if a unit has a specific buff by its icon
function HasBuffWithIcon(unit, iconPath)
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
function IsWithinRange(unit, rangeType)
    return CheckInteractDistance(unit, rangeType);
end

-- Finds the lowest health unit below a health threshold in the group
function GetLowestHealthUnit(healthThreshold, spellName, rangeType)
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
function GetPlayersBelowHealthThresholdInRange(minHP)
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

-- Ensure an aura is active based on priority list
function aCheckAura()
    local currentAuraIndex = nil
    for i, aura in ipairs(AURA_PRIORITY) do
        if HasBuffWithIcon("player", aura.icon) then
            currentAuraIndex = i
            break
        end
    end
    if not currentAuraIndex then
        -- No aura active, cast the highest priority (Concentration Aura)
        CastSpellByName(AURA_PRIORITY[1].name, "player")
        DebugPrint(AURA_PRIORITY[1].name .. " --> player (No aura active)")
        return false
    else
        -- An aura is active, cast the next one in the priority list
        local nextAuraIndex = currentAuraIndex + 1
        if nextAuraIndex > 7 then
            nextAuraIndex = 1
        end
        CastSpellByName(AURA_PRIORITY[nextAuraIndex].name, "player")
        DebugPrint(AURA_PRIORITY[nextAuraIndex].name .. " --> player (Switching from " .. AURA_PRIORITY[currentAuraIndex].name .. ")")
        return false
    end
end

-- Ensure melee buffs (Seal of Wisdom and Holy Judgement) are active
function aMeleeBuffs()
    --if aCheckAura() then return true end
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
                        --DebugPrint("Crusader Strike : on cooldown");
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
    DebugPrint("MasterHealSequence called");
    if aCheckAura() then return true end
    if aHealWithHL(25) then return true end
    if aHealWithHS(90) then return true end
    if aCastHolyStrike(90, 4) then return true end
    if aHealWithHL(45) then return true end
    if aHealWithFoL(90) then return true end
    return false -- If none of the spells were cast
end