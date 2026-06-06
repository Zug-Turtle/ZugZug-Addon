ZugZug.LFG_TYPES = {
    { value = "Dungeon", label = "Dungeon" },
    { value = "Raid", label = "Raid" },
    { value = "Other", label = "Other" },
}

ZugZug.LFG_TARGETS = {}
ZugZug.LFG_TARGETS["Dungeon"] = {
    -- Vanilla
    "Ragefire Chasm",
    "Wailing Caverns",
    "Deadmines",
    "Shadowfang Keep",
    "Blackfathom Deeps",
    "Stormwind Stockade",
    "Gnomeregan",
    "Razorfen Kraul",
    "Scarlet Monastery",
    "Razorfen Downs",
    "Uldaman",
    "Zul'Farrak",
    "Maraudon",
    "Temple of Atal'Hakkar",
    "Blackrock Depths",
    "Lower Blackrock Spire",
    "Dire Maul",
    "Scholomance",
    "Stratholme",
    -- Turtle
    "Crescent Grove",
    "Hateforge Quarry",
    "Gilneas City",
    "Stormwind Vault",
    "Karazhan Crypt",
    "Black Morass",
    "Dragonmaw Retreat",
    "Stormwrought Ruins",
    "Windhorn Canyon",
    "Frostmane Hollow",
}

ZugZug.LFG_TARGETS["Raid"] = {
    -- Vanilla
    "Upper Blackrock Spire",
    "Onyxia's Lair",
    "Molten Core",
    "Blackwing Lair",
    "Zul'Gurub",
    "Ruins of Ahn'Qiraj",
    "Temple of Ahn'Qiraj",
    "Naxxramas",
    -- Turtle
    "Emerald Sanctum",
    "Lower Karazhan Halls",
    "Tower of Karazhan",
    "Timbermaw Hold",
}

ZugZug.LFG_TARGETS["Other"] = {}

ZugZug.LFG_ROLE_ICONS = {
    ["TANK"] = "Interface\\AddOns\\ZugZug\\Textures\\Tank",
    ["HEALER"] = "Interface\\AddOns\\ZugZug\\Textures\\Healer",
    ["DPS"] = "Interface\\AddOns\\ZugZug\\Textures\\DPS"
}

function ZugZug_LFG_GetTargetsForType(lfgType)
    if not lfgType or lfgType == "" then
        lfgType = "Dungeon"
    end
    if ZugZug.LFG_TARGETS and ZugZug.LFG_TARGETS[lfgType] then
        return ZugZug.LFG_TARGETS[lfgType]
    end
    return {}
end

function ZugZug_LFG_GetFirstTargetForType(lfgType)
    local targets = ZugZug_LFG_GetTargetsForType(lfgType)
    if targets and table.getn(targets) > 0 then
        return targets[1]
    end
    return ""
end

function ZugZug_LFG_GetRoleIcon(role)
    if ZugZug.LFG_ROLE_ICONS and ZugZug.LFG_ROLE_ICONS[role] then
        return ZugZug.LFG_ROLE_ICONS[role]
    end
    return "Interface\\AddOns\\ZugZug\\Textures\\DPS"
end