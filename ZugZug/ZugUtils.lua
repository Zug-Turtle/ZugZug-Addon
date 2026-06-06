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

function ZugZug_Log(msg) print("|cff00ff00[ZugZug]|r " .. msg) end

function ZugZug_InitDB()
    if not ZugZugDB then ZugZugDB = {} end

    if not ZugZugDB.addonUsers then ZugZugDB.addonUsers = {} end
    if not ZugZugDB.lfgRoles then ZugZugDB.lfgRoles = {} end
    if not ZugZugDB.officerChatLog then ZugZugDB.officerChatLog = {} end
    if not ZugZugDB.banlist then ZugZugDB.banlist = {} end
    if not ZugZugDB.classByName then ZugZugDB.classByName = {} end
    if not ZugZugDB.dashboardState then ZugZugDB.dashboardState = {} end
    if not ZugZug.guildChatLog then ZugZug.guildChatLog = {} end 

    if ZugZugDB.rosterSameZoneOnly == nil then
        ZugZugDB.rosterSameZoneOnly = false
    end

    if ZugZugDB.showWindowOnLogin == nil then
        ZugZugDB.showWindowOnLogin = false
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

function ZugZug_SaveClassForName(name, class)
    if not name or name == "" then return end
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

-- Advertising Macro if you wanna use it (mostly for Cows lol): /run ZugZugAdvertiseEnglish()
function ZugZugAdvertiseEnglish()
    local msg = "<" .. ZugZug.GUILD_NAME .. ">! English guild LFM! Previously 4k+ on Turtle, rebuilding here!"
        .. " Custom in-game NPC, Discord lvl tracking, custom tools, and more! Whisper 'inv' to " .. ZugZug.BOTNAME
        .. " for an invite. Join our Discord @ " .. ZugZug.DISCORD .. " !"
    local id = GetChannelName("English")
    if id and id > 0 then SendChatMessage(msg, "CHANNEL", nil, id) end
end
