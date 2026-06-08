ZugZug = {}
ZugZug.NAME = "ZugZug"
ZugZug.BOTNAME = "Zugbot"
ZugZug.VERSION = "0.1.0"
ZugZug.GUILD_NAME = "Zug Zug"
ZugZug.PREFIX = "ZUGZUG"
ZugZug.DISCORD = "https://discord.gg/cG27gCEK4c"

ZugZug.CLASS_COLORS = {
    ["Warrior"] = "ffc79c6e",
    ["Paladin"] = "fff58cba",
    ["Hunter"] = "ffabd473",
    ["Rogue"] = "fffff569",
    ["Priest"] = "ffffffff",
    ["Shaman"] = "ff0070de",
    ["Mage"] = "ff69ccf0",
    ["Warlock"] = "ff9482c9",
    ["Druid"] = "ffff7d0a",
}

ZugZug.CHUNK_SIZE = 170
ZugZug.MAX_RAW_SIZE = 230
ZugZug.CHUNK_TIMEOUT = 30
ZugZug.chunkSeq = 0
ZugZug.minimapAngle = 225
ZugZug.incomingChunks = {}
ZugZug.onlineMembers = {}
ZugZug.addonUsers = {}

ZugZug.locationBroadcastInterval = 5
ZugZug.locationPinUpdateInterval = 0.25
ZugZug.locationTimeout = 90
ZugZug.locationTicker = nil
ZugZug.locationPins = {}


function ZugZug_Log(msg) print("|cff00ff00[ZugZug]|r " .. msg) end

function ZugZug_InitDB()
    if not ZugZugDB then ZugZugDB = {} end

    if not ZugZugDB.addonUsers then ZugZugDB.addonUsers = {} end
    if not ZugZugDB.lfgRoles then ZugZugDB.lfgRoles = {} end
    if not ZugZugDB.officerChatLog then ZugZugDB.officerChatLog = {} end
    if not ZugZugDB.banlist then ZugZugDB.banlist = {} end
    if not ZugZugDB.classByName then ZugZugDB.classByName = {} end
    if not ZugZugDB.dashboardState then ZugZugDB.dashboardState = {} end
    if not ZugZugDB.dashboardIdentity then ZugZugDB.dashboardIdentity = {} end
    if not ZugZugDB.capyChatLog then ZugZugDB.capyChatLog = {} end
    if not ZugZug.guildChatLog then ZugZug.guildChatLog = {} end 

    if ZugZugDB.rosterSameZoneOnly == nil then
        ZugZugDB.rosterSameZoneOnly = false
    end

    if ZugZugDB.showWindowOnLogin == nil then
        ZugZugDB.showWindowOnLogin = false
    end

    if ZugZugDB.showGuildLocations == nil then
        ZugZugDB.showGuildLocations = false
    end

    if ZugZugDB.shareMyLocation == nil then
        ZugZugDB.shareMyLocation = false
    end

    if not ZugZugDB.window then
        ZugZugDB.window = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
        }
    end

    if not ZugZugDB.officerMacro then
        ZugZugDB.officerMacro = "bonk"
    end

    ZugZug.addonUsers = ZugZugDB.addonUsers
    ZugZug.rosterSameZoneOnly = ZugZugDB.rosterSameZoneOnly
    ZugZug.showWindowOnLogin = ZugZugDB.showWindowOnLogin
    ZugZug.officerChatLog = ZugZugDB.officerChatLog
    ZugZug.banlist = ZugZugDB.banlist
    ZugZug.officerMacro = ZugZugDB.officerMacro
    ZugZug.classByName = ZugZugDB.classByName
    ZugZug.dashboardState = ZugZugDB.dashboardState;
    ZugZug.dashboardIdentity = ZugZugDB.dashboardIdentity
    ZugZug.capyChatLog = ZugZugDB.capyChatLog
    ZugZug.showGuildLocations = ZugZugDB.showGuildLocations
    ZugZug.shareMyLocation = ZugZugDB.shareMyLocation

    if not ZugZug.guildLocations then
        ZugZug.guildLocations = {}
    end

    local playerName = UnitName("player")
    if playerName and ZugZugDB.lfgRoles[playerName] then
        local role = ZugZugDB.lfgRoles[playerName]

        if role == "TANK" or role == "HEALER" or role == "DPS" then
            if ZugZug.LFG then
                ZugZug.LFG.currentCreateRole = role
            end
        end
    end
end

function ZugZug_SetShowWindowOnLogin(enabled)
    if not ZugZugDB then ZugZugDB = {} end

    if enabled then
        ZugZugDB.showWindowOnLogin = true
        ZugZug.showWindowOnLogin = true
    else
        ZugZugDB.showWindowOnLogin = false
        ZugZug.showWindowOnLogin = false
    end
end

function ZugZug_GetShowWindowOnLogin()
    if ZugZug.showWindowOnLogin then
        return true
    end

    return false
end

function ZugZug_SaveWindowPosition(frame)
    if not frame then return end
    if not ZugZugDB then ZugZugDB = {} end

    local x, y = frame:GetCenter()

    if not x then x = 0 end
    if not y then y = 0 end

    ZugZugDB.window = {
        point = "CENTER",
        relativePoint = "BOTTOMLEFT",
        x = x,
        y = y,
    }
end

function ZugZug_GetWindowPosition()
    if ZugZugDB and ZugZugDB.window then
        return ZugZugDB.window
    end

    return {
        point = "CENTER",
        relativePoint = "BOTTOMLEFT",
        x = nil,
        y = nil,
    }
end

function ZugZug_SetShowGuildLocations(enabled)
    if not ZugZugDB then ZugZugDB = {} end
    if enabled then
        ZugZugDB.showGuildLocations = true
        ZugZug.showGuildLocations = true
    else
        ZugZugDB.showGuildLocations = false
        ZugZug.showGuildLocations = false
    end
end

function ZugZug_GetShowGuildLocations()
    if ZugZug.showGuildLocations then return true end
    return false
end

function ZugZug_SetShareMyLocation(enabled)
    if not ZugZugDB then ZugZugDB = {} end
    if enabled then
        ZugZugDB.shareMyLocation = true
        ZugZug.shareMyLocation = true
    else
        ZugZugDB.shareMyLocation = false
        ZugZug.shareMyLocation = false
    end
end

function ZugZug_GetShareMyLocation()
    if ZugZug.shareMyLocation then return true end
    return false
end

function ZugZug_NormalizeClass(class)
    if not class or class == "" then return "" end

    class = tostring(class)

    local lower = string.lower(class)

    if lower == "warrior" then return "Warrior" end
    if lower == "paladin" then return "Paladin" end
    if lower == "hunter" then return "Hunter" end
    if lower == "rogue" then return "Rogue" end
    if lower == "priest" then return "Priest" end
    if lower == "shaman" then return "Shaman" end
    if lower == "mage" then return "Mage" end
    if lower == "warlock" then return "Warlock" end
    if lower == "druid" then return "Druid" end

    return class
end

function ZugZug_SaveClassForName(name, class)
    if not name or name == "" then return end
    if not class or class == "" then return end

    class = ZugZug_NormalizeClass(class)

    if not class or class == "" then return end

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.classByName then ZugZugDB.classByName = {} end

    ZugZugDB.classByName[name] = class
    ZugZug.classByName = ZugZugDB.classByName
end

function ZugZug_GetClassForName(name)
    if not name or name == "" then return nil end

    if ZugZug.classByName and ZugZug.classByName[name] then
        return ZugZug.classByName[name]
    end

    if ZugZugDB and ZugZugDB.classByName and ZugZugDB.classByName[name] then
        return ZugZugDB.classByName[name]
    end

    return nil
end

function ZugZug_AddGuildChatLog(sender, msg)
    if not sender or sender == "" then return end
    if not msg or msg == "" then return end

    if not ZugZug.guildChatLog then
        ZugZug.guildChatLog = {}
    end

    table.insert(ZugZug.guildChatLog, {
        sender = sender,
        msg = msg,
        at = time(),
    })

    while table.getn(ZugZug.guildChatLog) > 120 do
        table.remove(ZugZug.guildChatLog, 1)
    end
end

function ZugZug_AddCapyChatLog(sender, msg, className, source)
    if not sender or sender == "" then return end
    if not msg or msg == "" then return end

    if className and className ~= "" then
        ZugZug_SaveClassForName(sender, className)
    end

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.capyChatLog then ZugZugDB.capyChatLog = {} end

    table.insert(ZugZugDB.capyChatLog, {
        sender = sender,
        msg = msg,
        className = className or "",
        source = source or "game",
        at = time(),
    })

    while table.getn(ZugZugDB.capyChatLog) > 120 do
        table.remove(ZugZugDB.capyChatLog, 1)
    end

    ZugZug.capyChatLog = ZugZugDB.capyChatLog
end

function ZugZug_SetDashboardStateFromPayload(payload)
    if not payload or payload == "" then return end

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.dashboardState then ZugZugDB.dashboardState = {} end

    local parts = {}
    local startPos = 1
    local index = 1

    while true do
        local pos = string.find(payload, ":", startPos, true)

        if pos then
            parts[index] = string.sub(payload, startPos, pos - 1)
            startPos = pos + 1
        else
            parts[index] = string.sub(payload, startPos)
            break
        end

        index = index + 1
    end

    ZugZugDB.dashboardState.shellGold = tonumber(parts[1] or "0") or 0
    ZugZugDB.dashboardState.shellSilver = tonumber(parts[2] or "0") or 0
    ZugZugDB.dashboardState.shellCopper = tonumber(parts[3] or "0") or 0

    ZugZugDB.dashboardState.dmfLocation = ZugZug_SafeDecodeText(parts[4] or "")
    ZugZugDB.dashboardState.dmfZone = ZugZug_SafeDecodeText(parts[5] or "")
    ZugZugDB.dashboardState.dmfNextLocation = ZugZug_SafeDecodeText(parts[6] or "")
    ZugZugDB.dashboardState.dmfNextZone = ZugZug_SafeDecodeText(parts[7] or "")
    ZugZugDB.dashboardState.dmfNextAt = tonumber(parts[8] or "0") or 0

    ZugZugDB.dashboardState.guildMotd = ZugZug_SafeDecodeText(parts[9] or "")
    ZugZugDB.dashboardState.updatedAt = time()

    ZugZug.dashboardState = ZugZugDB.dashboardState
end

function ZugZug_UpdateDashboardMOTDFromGuild()
    if not GetGuildRosterMOTD then return false end

    local motd = GetGuildRosterMOTD() or ""

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.dashboardState then ZugZugDB.dashboardState = {} end

    if ZugZugDB.dashboardState.guildMotd == motd then
        ZugZug.dashboardState = ZugZugDB.dashboardState
        return false
    end

    ZugZugDB.dashboardState.guildMotd = motd
    ZugZugDB.dashboardState.motdUpdatedAt = time()
    ZugZug.dashboardState = ZugZugDB.dashboardState
    return true
end

local function ZugZug_DecodeHexText(hex)
    if not hex or hex == "" then return "" end

    local out = ""
    local i = 1

    while i < string.len(hex) do
        local pair = string.sub(hex, i, i + 1)
        local n = tonumber(pair, 16)

        if not n then
            return ""
        end

        out = out .. string.char(n)
        i = i + 2
    end

    return out
end

local function ZugZug_EncodeHexText(text)
    if not text or text == "" then return "" end

    local out = ""
    local i = 1

    while i <= string.len(text) do
        out = out .. string.format("%02x", string.byte(text, i))
        i = i + 1
    end

    return out
end

local function ZugZug_SplitDelimited(value, delimiter)
    local fields = {}
    local fieldStart = 1
    local fieldIndex = 1

    while true do
        local fieldPos = string.find(value, delimiter, fieldStart, true)

        if fieldPos then
            fields[fieldIndex] = string.sub(value, fieldStart, fieldPos - 1)
            fieldStart = fieldPos + string.len(delimiter)
        else
            fields[fieldIndex] = string.sub(value, fieldStart)
            break
        end

        fieldIndex = fieldIndex + 1
    end

    return fields
end

local function ZugZug_IsSupportedIdentityRealm(key)
    key = string.lower(key or "")
    return key == "capycraft" or key == "turtle"
end

local function ZugZug_GetIdentityRealm(identity, key, name)
    if not identity.realmsByKey then
        identity.realmsByKey = {}
    end

    key = string.lower(key or "")

    if identity.realmsByKey[key] then
        return identity.realmsByKey[key]
    end

    local realm = {
        realmKey = key,
        realmName = name or key,
        characters = {},
    }

    identity.realmsByKey[key] = realm
    table.insert(identity.realms, realm)
    return realm
end

function ZugZug_SetDashboardIdentityFromPayload(payload)
    if not payload or payload == "" then return false end

    local sep = string.find(payload, ":", 1, true)
    if not sep then return false end

    local target = ZugZug_SafeDecodeText(string.sub(payload, 1, sep - 1))
    local body = ZugZug_DecodeHexText(string.sub(payload, sep + 1))
    local player = UnitName("player")

    if not target or target == "" then return false end
    if not player or string.lower(target) ~= string.lower(player) then return false end
    if not body or body == "" then return false end

    local bodySep = string.find(body, ":", 1, true)
    if not bodySep then return false end

    local verified = string.sub(body, 1, bodySep - 1)
    local rows = string.sub(body, bodySep + 1)

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.dashboardIdentity then ZugZugDB.dashboardIdentity = {} end

    local identity = {
        target = target,
        verified = (verified == "1"),
        updatedAt = time(),
        characters = {},
        realms = {},
        realmsByKey = {},
    }

    local rowStart = 1

    while rows and rows ~= "" do
        local rowPos = string.find(rows, "%^", rowStart)
        local row = nil

        if rowPos then
            row = string.sub(rows, rowStart, rowPos - 1)
            rowStart = rowPos + 1
        else
            row = string.sub(rows, rowStart)
            rows = ""
        end

        if row and row ~= "" then
            local fields = ZugZug_SplitDelimited(row, "|")
            local realmKey = nil
            local realmName = nil
            local name = nil
            local level = 0
            local className = nil
            local isCurrent = false

            if fields[6] ~= nil and ZugZug_IsSupportedIdentityRealm(fields[1] or "") then
                realmKey = string.lower(fields[1] or "")
                realmName = ZugZug_SafeDecodeText(fields[2] or "")
                name = ZugZug_SafeDecodeText(fields[3] or "")
                level = tonumber(fields[4] or "0") or 0
                className = ZugZug_NormalizeClass(ZugZug_SafeDecodeText(fields[5] or ""))
                isCurrent = (fields[6] == "1")
            else
                name = ZugZug_SafeDecodeText(fields[1] or "")
                level = tonumber(fields[2] or "0") or 0
                className = ZugZug_NormalizeClass(ZugZug_SafeDecodeText(fields[3] or ""))
                isCurrent = (fields[4] == "1")

                if fields[6] ~= nil then
                    isCurrent = (fields[6] == "1")
                end
            end

            if name and name ~= "" and string.lower(name) ~= string.lower(ZugZug.BOTNAME or "") then
                if className and className ~= "" then
                    ZugZug_SaveClassForName(name, className)
                end

                local character = {
                    name = name,
                    level = level,
                    className = className,
                    realmKey = realmKey,
                    realmName = realmName,
                    isCurrent = isCurrent,
                }

                table.insert(identity.characters, character)

                if realmKey then
                    local realm = ZugZug_GetIdentityRealm(identity, realmKey, realmName)
                    table.insert(realm.characters, character)
                end
            end
        end

        if rows == "" then break end
    end

    identity.realmsByKey = nil
    ZugZugDB.dashboardIdentity = identity
    ZugZug.dashboardIdentity = ZugZugDB.dashboardIdentity
    return true
end

function ZugZug_AddCapyChatFromPayload(payload)
    if not payload or payload == "" then return false end

    local body = ZugZug_DecodeHexText(payload)
    if not body or body == "" then return false end

    local fields = ZugZug_SplitDelimited(body, "|")
    local sender = ZugZug_SafeDecodeText(fields[1] or "")
    local className = ZugZug_NormalizeClass(ZugZug_SafeDecodeText(fields[2] or ""))
    local msg = ZugZug_SafeDecodeText(fields[3] or "")
    local source = ZugZug_SafeDecodeText(fields[4] or "discord")

    if not sender or sender == "" then return false end
    if not msg or msg == "" then return false end

    ZugZug_AddCapyChatLog(sender, msg, className, source)
    return true
end

function ZugZug_AddCapyChatFromSendPayload(sender, payload)
    if not sender or sender == "" then return false end
    if not payload or payload == "" then return false end

    local msg = ZugZug_DecodeHexText(payload)
    if not msg or msg == "" then return false end

    ZugZug_AddCapyChatLog(sender, msg, ZugZug_GetClassForName(sender) or "", "game")
    return true
end

function ZugZug_SendCapyChatMessage(msg)
    msg = ZugZug_NormalizeString(msg)
    if not msg then return false end

    local sender = UnitName("player") or "You"
    ZugZug_AddCapyChatLog(sender, msg, ZugZug_GetClassForName(sender) or "", "game")
    ZugZug_BroadcastAddon("CAPY_CHAT_SEND~" .. ZugZug_EncodeHexText(msg))
    return true
end

function ZugZug_FormatMoney(gold, silver, copper)
    gold = tonumber(gold or 0) or 0
    silver = tonumber(silver or 0) or 0
    copper = tonumber(copper or 0) or 0

    return tostring(gold) .. "g " .. tostring(silver) .. "s " .. tostring(copper) .. "c"
end

function ZugZug_SetOfficerMacro(value)
    if not value or value == "" then
        value = "bonk"
    end

    if not ZugZugDB then ZugZugDB = {} end

    ZugZugDB.officerMacro = value
    ZugZug.officerMacro = value
end

function ZugZug_GetOfficerMacro()
    if ZugZug.officerMacro and ZugZug.officerMacro ~= "" then
        return ZugZug.officerMacro
    end

    return "bonk"
end

function ZugZug_AddOfficerChatLog(sender, msg)
    if not sender or sender == "" then return end
    if not msg or msg == "" then return end

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.officerChatLog then ZugZugDB.officerChatLog = {} end

    table.insert(ZugZugDB.officerChatLog, {
        sender = sender,
        msg = msg,
        at = time(),
    })

    while table.getn(ZugZugDB.officerChatLog) > 80 do
        table.remove(ZugZugDB.officerChatLog, 1)
    end

    ZugZug.officerChatLog = ZugZugDB.officerChatLog
end

function ZugZug_ClearOfficerChatLog()
    if not ZugZugDB then ZugZugDB = {} end
    ZugZugDB.officerChatLog = {}
    ZugZug.officerChatLog = ZugZugDB.officerChatLog
end

function ZugZug_SetBanlistFromPayload(payload)
    if not ZugZugDB then ZugZugDB = {} end
    ZugZugDB.banlist = {}

    if not payload or payload == "" then
        ZugZug.banlist = ZugZugDB.banlist
        return
    end

    local startPos = 1

    while true do
        local pos = string.find(payload, "~", startPos, true)
        local row

        if pos then
            row = string.sub(payload, startPos, pos - 1)
            startPos = pos + 1
        else
            row = string.sub(payload, startPos)
        end

        if row and row ~= "" then
            local sep = string.find(row, "^", 1, true)
            local name = row
            local reason = ""

            if sep then
                name = string.sub(row, 1, sep - 1)
                reason = string.sub(row, sep + 1)
            end

            name = ZugZug_SafeDecodeText(name or "")
            reason = ZugZug_SafeDecodeText(reason or "")

            name = ZugZug_NormalizeString(name)
            reason = ZugZug_NormalizeString(reason) or ""

            if name then
                table.insert(ZugZugDB.banlist, {
                    name = name,
                    reason = reason,
                })
            end
        end

        if not pos then break end
    end

    ZugZug.banlist = ZugZugDB.banlist
end

function ZugZug_SaveLFGRole(name, role)
    if not name or name == "" then
        name = UnitName("player")
    end

    if not name or name == "" then return end

    if role ~= "TANK" and role ~= "HEALER" and role ~= "DPS" then
        return
    end

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.lfgRoles then ZugZugDB.lfgRoles = {} end

    ZugZugDB.lfgRoles[name] = role
end

function ZugZug_GetSavedLFGRole(name)
    if not name or name == "" then
        name = UnitName("player")
    end

    if not name or name == "" then return nil end
    if not ZugZugDB then return nil end
    if not ZugZugDB.lfgRoles then return nil end

    local role = ZugZugDB.lfgRoles[name]

    if role == "TANK" or role == "HEALER" or role == "DPS" then
        return role
    end

    return nil
end

local function ZugZug_NewChunkId()
    ZugZug.chunkSeq = ZugZug.chunkSeq + 1
    if ZugZug.chunkSeq > 9999 then
        ZugZug.chunkSeq = 1
    end
    return UnitName("player") .. tostring(time()) .. tostring(ZugZug.chunkSeq)
end

local function ZugZug_SendRawAddon(msg, channel)
    if not msg then return end
    if not channel then channel = "GUILD" end
    SendAddonMessage(ZugZug.PREFIX, msg, channel)
end

function ZugZug_SendAddon(msg, channel)
    if not msg then return end
    if not channel then channel = "GUILD" end

    local maxRaw = ZugZug.MAX_RAW_SIZE - string.len(ZugZug.PREFIX)
    if string.len(msg) <= maxRaw then
        ZugZug_SendRawAddon(msg, channel)
        return
    end

    local chunkId = ZugZug_NewChunkId()
    local total = math.ceil(string.len(msg) / ZugZug.CHUNK_SIZE)
    local i = 1
    while i <= total do
        local startPos = ((i - 1) * ZugZug.CHUNK_SIZE) + 1
        local endPos = startPos + ZugZug.CHUNK_SIZE - 1
        local part = string.sub(msg, startPos, endPos)
        ZugZug_SendRawAddon("CHK~" .. chunkId .. "~" .. i .. "~" .. total .. "~" .. part, channel)
        i = i + 1
    end
end

function ZugZug_BroadcastAddon(msg) ZugZug_SendAddon(msg, "GUILD") end
function ZugZug_SendBotWhisper(msg) SendChatMessage(ZugZug.PREFIX .. "~" .. msg, "WHISPER", nil, ZugZug.BOTNAME) end

function ZugZug_SendBotCommand(command)
    command = ZugZug_NormalizeString(command)
    if not command then return end
    SendChatMessage("@" .. command, "WHISPER", nil, ZugZug.BOTNAME)
end

function ZugZug_SendOfficerBan(target, reason)
    target = ZugZug_NormalizeString(target)
    reason = ZugZug_NormalizeString(reason) or ""
    if not target then
        ZugZug_Log("Ban target required.")
        return nil
    end
    if reason ~= "" then
        ZugZug_SendBotCommand("ban " .. target .. " " .. reason)
    else
        ZugZug_SendBotCommand("ban " .. target)
    end
    return 1
end

function ZugZug_RunOfficerMacroCommand(macro)
    macro = ZugZug_NormalizeString(macro)
    if not macro then return end
    if macro == "donate" or macro == "donation" then
        ZugZug_SendBotCommand("donate")
        return
    end
    if macro == "bonk" or macro == "moderate" then 
        ZugZug_SendBotCommand("bonk")
        return
    end
end

local function ZugZug_CleanupChunks()
    local now = GetTime()
    for key, entry in pairs(ZugZug.incomingChunks) do
        if entry.created and now - entry.created > ZugZug.CHUNK_TIMEOUT then
            ZugZug.incomingChunks[key] = nil
        end
    end
end

local function ZugZug_HandleChunk(data, sender)
    ZugZug_CleanupChunks()

    local a = string.find(data, "~", 1, true)
    if not a then return nil end

    local b = string.find(data, "~", a + 1, true)
    if not b then return nil end

    local c = string.find(data, "~", b + 1, true)
    if not c then return nil end

    local chunkId = string.sub(data, 1, a - 1)
    local index = tonumber(string.sub(data, a + 1, b - 1))
    local total = tonumber(string.sub(data, b + 1, c - 1))
    local part = string.sub(data, c + 1)

    if not chunkId or chunkId == "" then return nil end
    if not index or not total then return nil end
    if index < 1 or total < 1 or index > total then return nil end
    if total > 100 then return nil end

    local key = tostring(sender or "UNKNOWN") .. ":" .. chunkId

    if not ZugZug.incomingChunks[key] then
        ZugZug.incomingChunks[key] = {
            total = total,
            count = 0,
            parts = {},
            created = GetTime()
        }
    end

    local entry = ZugZug.incomingChunks[key]
    if entry.total ~= total then
        ZugZug.incomingChunks[key] = nil
        return nil
    end
    if not entry.parts[index] then
        entry.parts[index] = part
        entry.count = entry.count + 1
    end
    if entry.count < entry.total then
        return nil
    end

    local full = ""
    local i = 1
    while i <= entry.total do
        if not entry.parts[i] then
            return nil
        end
        full = full .. entry.parts[i]
        i = i + 1
    end
    ZugZug.incomingChunks[key] = nil
    return full
end

function ZugZug_RebuildIncomingMessage(message, sender)
    if not message or message == "" then return nil end
    local sep = string.find(message, "~", 1, true)
    if not sep then return message end
    local cmd = string.upper(string.sub(message, 1, sep - 1))
    local data = string.sub(message, sep + 1)
    if cmd ~= "CHK" then return message end
    return ZugZug_HandleChunk(data, sender)
end

function ZugZug_isOfficerOrGM(name)
    if not IsInGuild() then return false end
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local fullName, rank, rankIndex = GetGuildRosterInfo(i)
        if fullName and string.lower(fullName) == string.lower(name) then
            if rankIndex <= 2 then -- (GM=0, Spirit Walker=1, Officer=2)
                return true
            end
        end
    end
    return false
end

function ZugZug_isGuildMember(name)
    if not IsInGuild() then return false end
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local fullName = GetGuildRosterInfo(i)
        if fullName and string.lower(fullName) == string.lower(name) then 
            return true
        end
    end
    return false
end

function ZugZug_FixColors(str) return string.gsub(str, "\\124", "|") end

function ZugZug_SafeEncodeText(s)
    if not s then return "" end

    s = string.gsub(s, "&", "&#38;")
    s = string.gsub(s, ":", "&#58;")
    s = string.gsub(s, "~", "&#126;")
    s = string.gsub(s, "%^", "&#94;")
    s = string.gsub(s, "|", "&#124;")
    s = string.gsub(s, "\r", "")
    s = string.gsub(s, "\n", "&#10;")

    return s
end

function ZugZug_SafeDecodeText(s)
    if not s then return "" end

    s = string.gsub(s, "&#10;", "\n")
    s = string.gsub(s, "&#124;", "|")
    s = string.gsub(s, "&#94;", "^")
    s = string.gsub(s, "&#126;", "~")
    s = string.gsub(s, "&#58;", ":")
    s = string.gsub(s, "&#38;", "&")

    return s
end

function ZugZug_NormalizeString(str)
    local text = tostring(str or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    if text == "" then return nil end
    return text
end

function ZugZug_ParseCommand(msg)
    local text = msg or ""
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    if text == "" then return "", "" end
    local spacePos = string.find(text, " ", 1, true)
    local cmd = ""
    local args = ""
    if spacePos then
        cmd = string.sub(text, 1, spacePos - 1)
        args = string.sub(text, spacePos + 1)
    else
        cmd = text
        args = ""
    end
    cmd = string.lower(cmd)
    args = string.gsub(args, "^%s+", "")
    args = string.gsub(args, "%s+$", "")
    return cmd, args
end

function ZugZug_SetRosterSameZoneOnly(enabled)
    if not ZugZugDB then ZugZugDB = {} end
    if enabled then
        ZugZugDB.rosterSameZoneOnly = true
        ZugZug.rosterSameZoneOnly = true
    else
        ZugZugDB.rosterSameZoneOnly = false
        ZugZug.rosterSameZoneOnly = false
    end
end

function ZugZug_IsRosterSameZoneOnly()
    if ZugZug.rosterSameZoneOnly then return true end
    return false
end

function ZugZug_SortOnlineMembers()
    if not ZugZug.onlineMembers then return end

    table.sort(ZugZug.onlineMembers, function(a, b)
        local aRank = 999
        local bRank = 999

        if a and a.rankIndex then aRank = tonumber(a.rankIndex) or 999 end
        if b and b.rankIndex then bRank = tonumber(b.rankIndex) or 999 end

        if aRank == 0 and bRank ~= 0 then return true end
        if bRank == 0 and aRank ~= 0 then return false end

        local aOfficer = false
        local bOfficer = false
        if aRank <= 2 then aOfficer = true end
        if bRank <= 2 then bOfficer = true end
        if aOfficer ~= bOfficer then
            return aOfficer
        end

        local aLevel = 0
        local bLevel = 0
        if a and a.level then aLevel = tonumber(a.level) or 0 end
        if b and b.level then bLevel = tonumber(b.level) or 0 end
        if aLevel ~= bLevel then
            return aLevel > bLevel
        end

        local aZone = ""
        local bZone = ""
        if a and a.zone then aZone = string.lower(a.zone) end
        if b and b.zone then bZone = string.lower(b.zone) end
        if aZone ~= bZone then
            return aZone < bZone
        end

        local aName = ""
        local bName = ""
        if a and a.name then aName = string.lower(a.name) end
        if b and b.name then bName = string.lower(b.name) end
        return aName < bName
    end)
end

function ZugZug_UpdateOnlineMembers()
    ZugZug.onlineMembers = {}
    if not IsInGuild() then return end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return end
    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.classByName then ZugZugDB.classByName = {} end
    ZugZug.classByName = ZugZugDB.classByName

    local numMembers = GetNumGuildMembers()
    if not numMembers then return end

    local i = 1
    while i <= numMembers do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online = GetGuildRosterInfo(i)
        if name and class and class ~= "" then
            ZugZug_SaveClassForName(name, class)
        end
        if online and name and string.lower(name) ~= string.lower(ZugZug.BOTNAME) then
            table.insert(ZugZug.onlineMembers, {
                name = name,
                class = class,
                rank = rank,
                rankIndex = rankIndex,
                level = level,
                zone = zone,
            })
        end
        i = i + 1
    end
    ZugZug_SortOnlineMembers()
end

function ZugZug_RecordAddonUser(name, version)
    if not name or name == "" then return end
    if not version or version == "" then version = "unknown" end

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.addonUsers then ZugZugDB.addonUsers = {} end

    ZugZug.addonUsers = ZugZugDB.addonUsers
    ZugZug.addonUsers[name] = {
        version = version,
        lastSeen = time()
    }
end

function ZugZug_GetAddonVersionForMember(name)
    if not name or name == "" then return nil end
    if not ZugZug.addonUsers then return nil end
    local info = ZugZug.addonUsers[name]
    if info and info.version then return info.version end
    return nil
end

function ZugZug_ClassColorize(name)
    if not name or name == "" then return "" end
    if string.lower(name) == string.lower(ZugZug.BOTNAME) then
        return "|cffffd100" .. name .. "|r"
    end
    local class = ZugZug_GetClassForName(name)
    if not class then
        local i = 1
        while ZugZug.onlineMembers and i <= table.getn(ZugZug.onlineMembers) do
            local member = ZugZug.onlineMembers[i]
            if member and member.name == name then
                class = member.class
                break
            end
            i = i + 1
        end
    end
    if class and ZugZug.CLASS_COLORS[class] then
        return "|c" .. ZugZug.CLASS_COLORS[class] .. name .. "|r"
    end
    return name
end

function ZugZug_ColorMessage(msg, sender)
    if not msg then return "" end
    local coloredSender = ZugZug_ClassColorize(sender)
    local result = ""
    local lastPos = 1
    while true do
        local s, e = string.find(msg, "|r", lastPos, true)
        if not s then break end
        result = result .. string.sub(msg, lastPos, e) .. "|cff00ff00"
        lastPos = e + 1
    end
    result = result .. string.sub(msg, lastPos)
    return "|cff00ff00[|r" .. coloredSender .. "|cff00ff00]|r |cff00ff00" .. result .. "|r"
end

function ZugZug_ColorOfficerMessage(msg, sender)
    if not msg then return "" end
    local coloredSender = ZugZug_ClassColorize(sender)
    local result = ""
    local lastPos = 1
    while true do
        local s, e = string.find(msg, "|r", lastPos, true)
        if not s then break end
        result = result .. string.sub(msg, lastPos, e) .. "|cff00ffff"
        lastPos = e + 1
    end
    result = result .. string.sub(msg, lastPos)
    return "|cff00ffff[|r" .. coloredSender .. "|cff00ffff]|r |cff00ffff" .. result .. "|r"
end

function ZugZug_Wait(delay, func)
    local start = GetTime()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function()
        if GetTime() - start >= delay then
            frame:SetScript("OnUpdate", nil)
            func()
            frame = nil
        end
    end)
end

function ZugZug_FormatTimeRemaining(timestamp)
    timestamp = tonumber(timestamp or 0) or 0
    local now = time()
    local diff = timestamp - now
    if diff <= 0 then return "now" end
    local days = floor(diff / 86400)
    local rem = diff - (days * 86400)
    local hours = floor(rem / 3600)
    rem = rem - (hours * 3600)
    local mins = floor(rem / 60)
    local secs = rem - (mins * 60)
    local txt = ""
    if days > 0 then
        txt = txt .. tostring(days) .. "d "
    end
    if hours > 0 or days > 0 then
        txt = txt .. tostring(hours) .. "h "
    end
    if mins > 0 or hours > 0 or days > 0 then
        txt = txt .. tostring(mins) .. "m "
    end
    txt = txt .. tostring(secs) .. "s"
    return txt
end

function ZugZug_HandleLogin()
    if not IsInGuild() then
        ZugZug_Log("You are not in a guild! Join |cff00ff00<" .. ZugZug.GUILD_NAME .. ">|r to use this addon.")
        return
    end
    local guildName, guildRank, guildRankIndex = GetGuildInfo("player")
    if guildName == ZugZug.GUILD_NAME then
        if GuildRoster then GuildRoster() end
        ZugZug_RecordAddonUser(UnitName("player"), ZugZug.VERSION)
        ZugZug_UpdateOnlineMembers()
        ZugZug_Log("Welcome back, |cff00ff00" .. guildRank .. "|r " .. ZugZug_ClassColorize(UnitName("player")) .. "!")
        ZugZug_Log("You are a proud member of |cff00ff00<" .. guildName .. ">|r.")
        if guildRankIndex and guildRankIndex <= 2 then
            ZugZug_Log("|cff00ffffOfficer|r access granted.")
        end
        ZugZug_BroadcastAddon("LOGIN~" .. ZugZug.VERSION)
        ZugZug.READY = true
    else
        ZugZug_Log("Unfortunately you are not a member of |cff00ff00<" .. ZugZug.GUILD_NAME .. ">|r. Sorry you're lame.")
    end
end

local function ZugZug_HexPairToNumber(pair)
    local n = tonumber(pair or "ff", 16)
    if not n then n = 255 end
    return n / 255
end

function ZugZug_GetClassRGB(class)
    class = ZugZug_NormalizeClass(class)
    local hex = nil
    if class and class ~= "" and ZugZug.CLASS_COLORS then
        hex = ZugZug.CLASS_COLORS[class]
    end
    if not hex or string.len(hex) < 8 then
        return 1, 0.82, 0
    end

    local r = ZugZug_HexPairToNumber(string.sub(hex, 3, 4))
    local g = ZugZug_HexPairToNumber(string.sub(hex, 5, 6))
    local b = ZugZug_HexPairToNumber(string.sub(hex, 7, 8))
    return r, g, b
end

local function ZugZug_GetCurrentMapInfoSafe()
    if GetMapInfo then
        return GetMapInfo() or ""
    end

    return ""
end

local function ZugZug_GetMyMapPositionSafe()
    local oldContinent = nil
    local oldZone = nil

    if GetCurrentMapContinent then
        oldContinent = GetCurrentMapContinent()
    end

    if GetCurrentMapZone then
        oldZone = GetCurrentMapZone()
    end

    if SetMapToCurrentZone then
        SetMapToCurrentZone()
    end

    local mapFile = ZugZug_GetCurrentMapInfoSafe()
    local zone = ""

    if GetRealZoneText then
        zone = GetRealZoneText() or ""
    elseif GetZoneText then
        zone = GetZoneText() or ""
    end

    local x = 0
    local y = 0

    if GetPlayerMapPosition then
        x, y = GetPlayerMapPosition("player")
    end

    if oldContinent and oldZone and oldContinent > 0 then
        if SetMapZoom then
            SetMapZoom(oldContinent, oldZone)
        end
    end

    if not x then x = 0 end
    if not y then y = 0 end

    return mapFile, zone, x, y
end

function ZugZug_BroadcastMyLocation()
    if not ZugZug_GetShareMyLocation or not ZugZug_GetShareMyLocation() then return end
    if not IsInGuild or not IsInGuild() then return end

    local mapFile, zone, x, y = ZugZug_GetMyMapPositionSafe()

    if not mapFile or mapFile == "" then return end
    if not zone or zone == "" then return end
    if not x or not y then return end
    if x <= 0 and y <= 0 then return end

    local className, englishClass = UnitClass("player")
    local class = ZugZug_NormalizeClass(className or englishClass or "")

    local xi = math.floor((x * 10000) + 0.5)
    local yi = math.floor((y * 10000) + 0.5)

    ZugZug_BroadcastAddon("LOC~"
        .. ZugZug_SafeEncodeText(mapFile) .. ":"
        .. ZugZug_SafeEncodeText(zone) .. ":"
        .. tostring(xi) .. ":"
        .. tostring(yi) .. ":"
        .. ZugZug_SafeEncodeText(class) .. ":"
        .. tostring(time())
    )
end

function ZugZug_SetGuildLocationFromPayload(sender, payload)
    if not sender or sender == "" then return end
    if sender == UnitName("player") then return end
    if not payload or payload == "" then return end

    if not ZugZug_GetShowGuildLocations or not ZugZug_GetShowGuildLocations() then
        return
    end

    local parts = {}
    local startPos = 1
    local index = 1

    while true do
        local pos = string.find(payload, ":", startPos, true)

        if pos then
            parts[index] = string.sub(payload, startPos, pos - 1)
            startPos = pos + 1
        else
            parts[index] = string.sub(payload, startPos)
            break
        end

        index = index + 1
    end

    local mapFile = ZugZug_SafeDecodeText(parts[1] or "")
    local zone = ZugZug_SafeDecodeText(parts[2] or "")
    local xi = tonumber(parts[3] or "0") or 0
    local yi = tonumber(parts[4] or "0") or 0
    local class = ZugZug_NormalizeClass(ZugZug_SafeDecodeText(parts[5] or ""))
    local sentAt = tonumber(parts[6] or "0") or time()

    if mapFile == "" then return end
    if xi <= 0 and yi <= 0 then return end

    if class and class ~= "" then
        ZugZug_SaveClassForName(sender, class)
    else
        class = ZugZug_GetClassForName(sender) or ""
    end

    if not ZugZug.guildLocations then
        ZugZug.guildLocations = {}
    end

    ZugZug.guildLocations[sender] = {
        name = sender,
        mapFile = mapFile,
        zone = zone,
        x = xi / 10000,
        y = yi / 10000,
        class = class,
        updatedAt = sentAt,
    }
end

function ZugZug_PruneGuildLocations()
    if not ZugZug.guildLocations then return end

    local now = time()

    for name, loc in pairs(ZugZug.guildLocations) do
        if not loc or not loc.updatedAt or now - loc.updatedAt > (ZugZug.locationTimeout or 90) then
            ZugZug.guildLocations[name] = nil
        end
    end
end

local function ZugZug_Map_HideAllPins()
    if not ZugZug.locationPins then return end

    local i = 1
    while ZugZug.locationPins[i] do
        ZugZug.locationPins[i]:Hide()
        i = i + 1
    end
end

local function ZugZug_Map_GetPin(index)
    if not ZugZug.locationPins then
        ZugZug.locationPins = {}
    end

    if ZugZug.locationPins[index] then
        return ZugZug.locationPins[index]
    end

    local pin = CreateFrame("Button", nil, WorldMapButton)
    pin:SetWidth(10)
    pin:SetHeight(10)
    pin:EnableMouse(true)
    pin:SetFrameLevel(WorldMapButton:GetFrameLevel() + 30)

    local border = pin:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", pin, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", 0, 0)
    border:SetTexture(0, 0, 0, 0.95)
    pin.border = border

    local box = pin:CreateTexture(nil, "ARTWORK")
    box:SetPoint("TOPLEFT", pin, "TOPLEFT", 2, -2)
    box:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", -2, 2)
    box:SetTexture(1, 0.82, 0, 1)
    pin.texture = box

    local hover = pin:CreateTexture(nil, "OVERLAY")
    hover:SetPoint("TOPLEFT", pin, "TOPLEFT", -2, 2)
    hover:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", 2, -2)
    hover:SetTexture(1, 1, 1, 0)
    pin.hover = hover

    pin:SetScript("OnEnter", function()
        if this.hover then
            this.hover:SetTexture(1, 1, 1, 0.28)
        end

        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")

        local name = this.guildName or "Guild member"
        local r = this.guildR or 1
        local g = this.guildG or 0.82
        local b = this.guildB or 0

        GameTooltip:SetText(name, r, g, b)

        if this.guildZone and this.guildZone ~= "" then
            GameTooltip:AddLine(this.guildZone, 0.7, 0.7, 0.7)
        end

        GameTooltip:Show()
    end)

    pin:SetScript("OnLeave", function()
        if this.hover then
            this.hover:SetTexture(1, 1, 1, 0)
        end

        GameTooltip:Hide()
    end)

    ZugZug.locationPins[index] = pin
    return pin
end

function ZugZug_Map_UpdateGuildPins()
    if not ZugZug_GetShowGuildLocations or not ZugZug_GetShowGuildLocations() then
        ZugZug_Map_HideAllPins()
        return
    end

    if not WorldMapFrame or not WorldMapFrame:IsShown() then
        ZugZug_Map_HideAllPins()
        return
    end

    if not WorldMapButton then
        return
    end

    ZugZug_PruneGuildLocations()

    local currentMap = ZugZug_GetCurrentMapInfoSafe()
    if not currentMap or currentMap == "" then
        ZugZug_Map_HideAllPins()
        return
    end

    local mapWidth = WorldMapButton:GetWidth()
    local mapHeight = WorldMapButton:GetHeight()

    if not mapWidth or not mapHeight or mapWidth <= 0 or mapHeight <= 0 then
        ZugZug_Map_HideAllPins()
        return
    end

    local used = 0

    for name, loc in pairs(ZugZug.guildLocations or {}) do
        if loc and loc.mapFile == currentMap and loc.x and loc.y then
            used = used + 1

            local pin = ZugZug_Map_GetPin(used)
            local class = loc.class or ""
            if class == "" and ZugZug_GetClassForName then
                class = ZugZug_GetClassForName(name) or ""
            end
            class = ZugZug_NormalizeClass(class)
            local r, g, b = ZugZug_GetClassRGB(class)

            pin.guildName = name
            pin.guildZone = loc.zone or ""
            pin.guildR = r
            pin.guildG = g
            pin.guildB = b

            pin.texture:SetTexture(r, g, b, 1)

            if pin.border then
                pin.border:SetTexture(0, 0, 0, 0.95)
            end

            if pin.hover then
                pin.hover:SetTexture(1, 1, 1, 0)
            end

            pin:ClearAllPoints()

            pin:SetPoint("CENTER", WorldMapButton, "TOPLEFT", loc.x * mapWidth, -(loc.y * mapHeight))
            pin:Show()
        end
    end

    local i = used + 1
    while ZugZug.locationPins and ZugZug.locationPins[i] do
        ZugZug.locationPins[i]:Hide()
        i = i + 1
    end
end

function ZugZug_Location_StartTicker()
    if ZugZug.locationTicker then return end

    local frame = CreateFrame("Frame")
    frame.lastBroadcast = 0
    frame.lastPinUpdate = 0

    frame:SetScript("OnUpdate", function()
        local now = GetTime()

        if now - (this.lastBroadcast or 0) >= (ZugZug.locationBroadcastInterval or 5) then
            this.lastBroadcast = now
            ZugZug_BroadcastMyLocation()
        end

        if now - (this.lastPinUpdate or 0) >= (ZugZug.locationPinUpdateInterval or 0.25) then
            this.lastPinUpdate = now
            ZugZug_Map_UpdateGuildPins()
        end
    end)

    ZugZug.locationTicker = frame
end

-- Advertising Macro if you wanna use it (mostly for Cows lol): /run ZugZugAdvertiseEnglish()
function ZugZugAdvertiseEnglish()
    local msg = "<" .. ZugZug.GUILD_NAME .. ">! English guild LFM! Previously 4k+ on Turtle, rebuilding here!"
        .. " Custom in-game NPC, Discord lvl tracking, custom tools, and more! Whisper 'inv' to " .. ZugZug.BOTNAME
        .. " for an invite. Join our Discord @ " .. ZugZug.DISCORD .. " !"
    local id = GetChannelName("English")
    if id and id > 0 then SendChatMessage(msg, "CHANNEL", nil, id) end
end
