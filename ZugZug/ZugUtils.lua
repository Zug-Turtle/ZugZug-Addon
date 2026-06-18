ZugZug = {}
ZugZug.NAME = "ZugZug"
ZugZug.BOTNAME = "Zugbot"
ZugZug.VERSION = "1.0.2"
ZugZug.GUILD_NAME = "Zug Zug"
ZugZug.PREFIX = "ZUGZUG"
ZugZug.DISCORD = "https://discord.gg/cG27gCEK4c"
ZugZug.READY = false

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
ZugZug.MAX_INCOMING_CHUNKS = 80
ZugZug.CAPY_CHAT_MAX_MESSAGES = 100
ZugZug.AH_MAX_SEARCH_LOG = 100
ZugZug.chunkSeq = 0
ZugZug.minimapAngle = 225
ZugZug.incomingChunks = {}
ZugZug.onlineMembers = {}
ZugZug.addonUsers = {}
ZugZug.friendsByName = {}

ZugZug.locationBroadcastInterval = 5
ZugZug.locationPinUpdateInterval = 0.25 
ZugZug.locationTimeout = 90
ZugZug.locationTicker = nil
ZugZug.locationPins = {}
ZugZug.ahSearchLog = {}
ZugZug.ahPriceCacheByItemId = {}
ZugZug.ahEnabled = false


function ZugZug_Log(msg) print("|cff00ff00[Zug Zug]|r " .. msg) end

function ZugZug_IsGuildAllowed()
    if not IsInGuild or not IsInGuild() then
        return false
    end
    if not GetGuildInfo then
        return false
    end
    local guildName = GetGuildInfo("player")
    if guildName == ZugZug.GUILD_NAME then
        return true
    end
    return false
end

function ZugZug_DisableForNonGuild()
    ZugZug.READY = false
    if ZugZug.UI then
        if ZugZug.UI.frame then
            ZugZug.UI.frame:Hide()
        end
        if ZugZug.UI.refreshTickerFrame then
            ZugZug.UI.refreshTickerFrame:SetScript("OnUpdate", nil)
        end
        ZugZug.UI.activeTab = nil
        ZugZug.UI.refreshScheduled = nil
        ZugZug.UI.refreshDelay = nil
    end

    if ZugZug.LFG and ZugZug.LFG.ticker then
        ZugZug.LFG.ticker:SetScript("OnUpdate", nil)
        ZugZug.LFG.ticker = nil
    end

    if ZugZug.locationTicker then
        ZugZug.locationTicker:SetScript("OnUpdate", nil)
        ZugZug.locationTicker = nil
    end
end

function ZugZug_ClearTable(t)
    if not t then return end
    for key in pairs(t) do
        t[key] = nil
    end
    t.n = 0
end

function ZugZug_GetOnlineMemberCount()
    local count = 0
    if not ZugZug.onlineMembers then
        return count
    end
    for key, member in pairs(ZugZug.onlineMembers) do
        if key ~= "n" and member and member.name then
            count = count + 1
        end
    end
    return count
end

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
    if not ZugZugDB.ahSearchLog then ZugZugDB.ahSearchLog = {} end
    if not ZugZugDB.ahPriceCacheByItemId then ZugZugDB.ahPriceCacheByItemId = {} end
    if not ZugZug.guildChatLog then ZugZug.guildChatLog = {} end 

    if ZugZugDB.rosterSameZoneOnly == nil then
        ZugZugDB.rosterSameZoneOnly = false
    end

    if ZugZugDB.rosterWithinMyLevelOnly == nil then
        ZugZugDB.rosterWithinMyLevelOnly = false
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

    if ZugZugDB.enableLFGNotifications == nil then
        ZugZugDB.enableLFGNotifications = true
    end

    if ZugZugDB.showCapyChatInMainChat == nil then
        ZugZugDB.showCapyChatInMainChat = false
    end

    if ZugZugDB.ahOnlyMine == nil then
        ZugZugDB.ahOnlyMine = false
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
    ZugZug.rosterWithinMyLevelOnly = ZugZugDB.rosterWithinMyLevelOnly
    ZugZug.showWindowOnLogin = ZugZugDB.showWindowOnLogin
    ZugZug.officerChatLog = ZugZugDB.officerChatLog
    ZugZug.banlist = ZugZugDB.banlist
    ZugZug.officerMacro = ZugZugDB.officerMacro
    ZugZug.classByName = ZugZugDB.classByName
    ZugZug.dashboardState = ZugZugDB.dashboardState;
    ZugZug.dashboardIdentity = ZugZugDB.dashboardIdentity
    ZugZug.capyChatLog = ZugZugDB.capyChatLog
    ZugZug.ahSearchLog = ZugZugDB.ahSearchLog
    ZugZug.ahPriceCacheByItemId = ZugZugDB.ahPriceCacheByItemId
    ZugZug.ahOnlyMine = ZugZugDB.ahOnlyMine
    ZugZug.showGuildLocations = ZugZugDB.showGuildLocations
    ZugZug.shareMyLocation = ZugZugDB.shareMyLocation
    ZugZug.enableLFGNotifications = ZugZugDB.enableLFGNotifications
    ZugZug.showCapyChatInMainChat = ZugZugDB.showCapyChatInMainChat

    if not ZugZug.guildLocations then
        ZugZug.guildLocations = {}
    end

    local playerName = UnitName("player")
    if playerName and ZugZugDB.lfgRoles[playerName] then
        local role = ZugZugDB.lfgRoles[playerName]

        if role == "TANK" or role == "HEALER" or role == "DPS" then
            if ZugZug.LFG then
                ZugZug.LFG.currentCreateRole = role
                ZugZug.LFG.currentCreateRoleOwner = playerName
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

function ZugZug_SetEnableLFGNotifications(enabled)
    if not ZugZugDB then ZugZugDB = {} end
    if enabled then
        ZugZugDB.enableLFGNotifications = true
        ZugZug.enableLFGNotifications = true
    else
        ZugZugDB.enableLFGNotifications = false
        ZugZug.enableLFGNotifications = false
    end
end

function ZugZug_GetEnableLFGNotifications()
    if ZugZug.enableLFGNotifications == false then return false end
    return true
end

function ZugZug_SetShowCapyChatInMainChat(enabled)
    if not ZugZugDB then ZugZugDB = {} end
    if enabled then
        ZugZugDB.showCapyChatInMainChat = true
        ZugZug.showCapyChatInMainChat = true
    else
        ZugZugDB.showCapyChatInMainChat = false
        ZugZug.showCapyChatInMainChat = false
    end
end

function ZugZug_GetShowCapyChatInMainChat()
    if ZugZug.showCapyChatInMainChat then return true end
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

    while table.getn(ZugZugDB.capyChatLog) > (ZugZug.CAPY_CHAT_MAX_MESSAGES or 100) do
        table.remove(ZugZugDB.capyChatLog, 1)
    end

    ZugZug.capyChatLog = ZugZugDB.capyChatLog
end

function ZugZug_ClearCapyChatLog()
    if not ZugZugDB then ZugZugDB = {} end

    ZugZugDB.capyChatLog = {}
    ZugZugDB.capyChatLog.n = 0
    ZugZug.capyChatLog = ZugZugDB.capyChatLog
end

function ZugZug_PrintCapyChatToMain(sender, msg, className)
    if not ZugZug_GetShowCapyChatInMainChat or not ZugZug_GetShowCapyChatInMainChat() then return end
    if not DEFAULT_CHAT_FRAME or not DEFAULT_CHAT_FRAME.AddMessage then return end
    if not sender or sender == "" then return end
    if not msg or msg == "" then return end

    if className and className ~= "" then
        ZugZug_SaveClassForName(sender, className)
    end

    local safeMsg = string.gsub(msg or "", "|", "||")
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0Discord #capy-chat|r " .. ZugZug_ClassColorize(sender) .. ": |cffd6e7ff" .. safeMsg .. "|r")
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

    if identity.verified then
        ZugZug.verifyCodeSubmittedAt = nil
        ZugZug.verifyIdentityRefreshSeq = nil
    end

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
    ZugZug_PrintCapyChatToMain(sender, msg, className)
    return true
end

function ZugZug_AddCapyChatFromSendPayload(sender, payload)
    if not sender or sender == "" then return false end
    if not payload or payload == "" then return false end

    local msg = ZugZug_DecodeHexText(payload)
    if not msg or msg == "" then return false end

    local className = ZugZug_GetClassForName(sender) or ""
    ZugZug_AddCapyChatLog(sender, msg, className, "game")

    local player = UnitName("player") or ""
    if string.lower(sender or "") ~= string.lower(player or "") then
        ZugZug_PrintCapyChatToMain(sender, msg, className)
    end
    return true
end

function ZugZug_SendCapyChatMessage(msg)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return false end

    msg = ZugZug_NormalizeString(msg)
    if not msg then return false end

    local sender = UnitName("player") or "You"
    ZugZug_AddCapyChatLog(sender, msg, ZugZug_GetClassForName(sender) or "", "game")
    ZugZug_BroadcastAddon("CAPY_CHAT_SEND~" .. ZugZug_EncodeHexText(msg))
    return true
end

function ZugZug_SendVerificationCode(text)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return false end

    text = ZugZug_NormalizeString(text)
    if not text then return false end

    local code = nil
    local firstSpace = string.find(text, " ", 1, true)

    if firstSpace then
        local first = string.sub(text, 1, firstSpace - 1)
        local rest = string.gsub(string.sub(text, firstSpace + 1), "^%s+", "")

        if string.lower(first or "") == "discord" then
            local restSpace = string.find(rest, " ", 1, true)
            if restSpace then
                code = string.sub(rest, 1, restSpace - 1)
            else
                code = rest
            end
        else
            code = first
        end
    else
        code = text
    end

    code = ZugZug_NormalizeString(code)
    if not code then return false end

    ZugZug_BroadcastAddon("VERIFY_CODE~" .. ZugZug_SafeEncodeText(code))
    ZugZug.verifyCodeSubmittedAt = time()
    ZugZug.verifyIdentityRefreshSeq = (ZugZug.verifyIdentityRefreshSeq or 0) + 1

    local refreshSeq = ZugZug.verifyIdentityRefreshSeq

    if ZugZug_Wait then
        ZugZug_Wait(2, function()
            if ZugZug.verifyIdentityRefreshSeq == refreshSeq and ZugZug_RequestDashboardIdentity then
                ZugZug_RequestDashboardIdentity("verify_2")
            end
        end)
        ZugZug_Wait(6, function()
            if ZugZug.verifyIdentityRefreshSeq == refreshSeq and ZugZug_RequestDashboardIdentity then
                ZugZug_RequestDashboardIdentity("verify_6")
            end
        end)
        ZugZug_Wait(12, function()
            if ZugZug.verifyIdentityRefreshSeq == refreshSeq and ZugZug_RequestDashboardIdentity then
                ZugZug_RequestDashboardIdentity("verify_12")
            end
        end)
    elseif ZugZug_RequestDashboardIdentity then
        ZugZug_RequestDashboardIdentity("verify")
    end

    return true
end

function ZugZug_RequestDashboardIdentity(reason)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return false end

    ZugZug_BroadcastAddon("LOGIN~" .. ZugZug.VERSION)
    return true
end

local ZugZug_AH_IsResultForMe

local function ZugZug_AH_GetContiguousCount(t)
    local count = 0
    while t and t[count + 1] do
        count = count + 1
    end
    return count
end

local function ZugZug_AH_RemoveLogRowAt(rows, index, count)
    if not rows or not index or not count then return end

    while index < count do
        rows[index] = rows[index + 1]
        index = index + 1
    end

    rows[count] = nil
end

local function ZugZug_AH_TrimRowsPreferNonMine(rows)
    if not rows then return 0 end

    local maxRows = ZugZug.AH_MAX_SEARCH_LOG or 100
    local count = ZugZug_AH_GetContiguousCount(rows)

    while count > maxRows do
        local removeIndex = count
        local i = count

        while i >= 1 do
            local row = rows[i]
            if row and not ZugZug_AH_IsResultForMe(row.requester or "") then
                removeIndex = i
                break
            end
            i = i - 1
        end

        ZugZug_AH_RemoveLogRowAt(rows, removeIndex, count)
        count = count - 1
    end

    rows.n = count
    return count
end

function ZugZug_AH_GetItemIdFromLink(link)
    if not link then return 0 end

    local _, _, itemId = string.find(link, "item:(%d+)")
    return tonumber(itemId) or 0
end

function ZugZug_AH_NormalizeIcon(icon)
    if type(icon) ~= "string" then return "" end
    icon = ZugZug_NormalizeString(icon or "") or ""
    if icon == "" then return "" end

    icon = string.gsub(icon, "/", "\\")

    local lower = string.lower(icon)
    local _, _, fileToken = string.find(lower, "icons\\large\\([^\\]+)%.jpg")
    if fileToken and fileToken ~= "" then
        icon = fileToken
    end

    if string.find(icon, "\\", 1, true) then
        return icon
    end

    icon = string.gsub(icon, "%.blp$", "")
    icon = string.gsub(icon, "%.jpg$", "")
    icon = string.gsub(icon, "%.tga$", "")

    if icon == "" then return "" end

    return "Interface\\Icons\\" .. icon
end

local function ZugZug_AH_IsIconTexture(value)
    if type(value) ~= "string" then return false end
    if value == "" then return false end

    local lower = string.lower(value)
    if string.find(lower, "interface\\icons\\", 1, true) then return true end
    if string.find(lower, "interface/icons/", 1, true) then return true end
    if string.find(lower, "^invtype_") then return false end
    if string.find(lower, "^inv_") then return true end
    if string.find(lower, "^spell_") then return true end
    if string.find(lower, "^ability_") then return true end
    if string.find(lower, "^trade_") then return true end
    if string.find(lower, "^item_") then return true end
    return false
end

local function ZugZug_AH_ReadItemInfo(link)
    local info = {
        name = "",
        link = link or "",
        texture = "",
    }

    if not GetItemInfo or not link or link == "" then
        return info
    end

    local name, resolvedLink, quality, level, typeName, subType, stackCount, equipLoc, textureOrSellPrice, sellPriceOrTexture = GetItemInfo(link)
    info.name = name or ""
    info.link = resolvedLink or link

    if ZugZug_AH_IsIconTexture(textureOrSellPrice) then
        info.texture = textureOrSellPrice
    elseif ZugZug_AH_IsIconTexture(sellPriceOrTexture) then
        info.texture = sellPriceOrTexture
    else
        info.texture = ""
    end

    return info
end

function ZugZug_AH_BuildItemLink(itemId)
    itemId = tonumber(itemId or 0) or 0
    if itemId <= 0 then return "" end
    return "item:" .. tostring(itemId) .. ":0:0:0"
end

local function ZugZug_AH_StripRealmName(name)
    local value = tostring(name or "")
    local dash = string.find(value, "-", 1, true)
    if dash then
        value = string.sub(value, 1, dash - 1)
    end
    return value
end

ZugZug_AH_IsResultForMe = function(requester)
    local player = UnitName and UnitName("player") or ""
    requester = ZugZug_AH_StripRealmName(requester)
    player = ZugZug_AH_StripRealmName(player)
    if requester == "" or player == "" then return false end
    return string.lower(requester) == string.lower(player)
end

function ZugZug_AH_IsRequesterMine(requester)
    return ZugZug_AH_IsResultForMe(requester)
end

local function ZugZug_AH_NormalizeResultLink(itemId, itemName, itemLink)
    itemId = tonumber(itemId or 0) or 0
    itemName = tostring(itemName or "")
    itemLink = tostring(itemLink or "")

    if itemId <= 0 then return itemLink end
    if itemLink == "" then
        itemLink = ZugZug_AH_BuildItemLink(itemId)
    end

    if string.find(itemLink, "item:", 1, true) and not string.find(itemLink, "|Hitem:", 1, true) and itemName ~= "" then
        return "|cffffffff|H" .. itemLink .. "|h[" .. itemName .. "]|h|r"
    end

    return itemLink
end

function ZugZug_AH_GetItemInfoFromLink(link)
    local itemId = ZugZug_AH_GetItemIdFromLink(link)
    local itemName = ""
    local itemLink = link or ""
    local icon = ""

    if GetItemInfo and (link and link ~= "") then
        local localInfo = ZugZug_AH_ReadItemInfo(link)
        itemName = localInfo.name or itemName
        itemLink = localInfo.link or itemLink
        icon = ZugZug_AH_NormalizeIcon(localInfo.texture or icon)
    end

    if itemName == "" and link then
        local _, _, linkedName = string.find(link, "%[(.-)%]")
        itemName = linkedName or ""
    end

    if itemName == "" and itemId > 0 then
        itemName = "Item " .. tostring(itemId)
    end

    return {
        itemId = itemId,
        itemName = itemName,
        itemLink = itemLink,
        icon = ZugZug_AH_NormalizeIcon(icon),
    }
end

function ZugZug_AH_FormatCopper(value)
    local copper = tonumber(value or 0) or 0
    if copper < 0 then copper = 0 end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper - (gold * 10000)) / 100)
    local copperOnly = copper - (gold * 10000) - (silver * 100)

    return tostring(gold) .. "g " .. tostring(silver) .. "s " .. tostring(copperOnly) .. "c"
end

function ZugZug_AH_TimeAgo(timestamp)
    local ts = tonumber(timestamp or 0) or 0
    if ts <= 0 then return "just now" end

    local diff = time() - ts
    if diff < 0 then diff = 0 end

    if diff < 60 then return tostring(diff) .. "s ago" end
    if diff < 3600 then return tostring(math.floor(diff / 60)) .. "m ago" end
    if diff < 86400 then return tostring(math.floor(diff / 3600)) .. "h ago" end
    return tostring(math.floor(diff / 86400)) .. "d ago"
end

function ZugZug_AH_PruneNonMineResults()
    if not ZugZugDB then return end

    if ZugZugDB.ahSearchLog then
        local kept = {}
        local keptIndex = 1
        local i = 1
        local count = ZugZug_AH_GetContiguousCount(ZugZugDB.ahSearchLog)

        while i <= count do
            local row = ZugZugDB.ahSearchLog[i]
            if row and ZugZug_AH_IsResultForMe(row.requester or "") then
                kept[keptIndex] = row
                keptIndex = keptIndex + 1
            end
            i = i + 1
        end

        ZugZug_ClearTable(ZugZugDB.ahSearchLog)

        i = 1
        while kept[i] do
            ZugZugDB.ahSearchLog[i] = kept[i]
            i = i + 1
        end

        ZugZugDB.ahSearchLog.n = keptIndex - 1
        ZugZug.ahSearchLog = ZugZugDB.ahSearchLog
    end

    if ZugZugDB.ahPriceCacheByItemId then
        for itemId, cached in pairs(ZugZugDB.ahPriceCacheByItemId) do
            if not cached or not ZugZug_AH_IsResultForMe(cached.requester or "") then
                ZugZugDB.ahPriceCacheByItemId[itemId] = nil
            end
        end

        ZugZug.ahPriceCacheByItemId = ZugZugDB.ahPriceCacheByItemId
    end
end

function ZugZug_AH_SetOnlyMine(enabled)
    if not ZugZugDB then ZugZugDB = {} end

    if enabled then
        ZugZugDB.ahOnlyMine = true
        ZugZug.ahOnlyMine = true
        ZugZug_AH_PruneNonMineResults()
    else
        ZugZugDB.ahOnlyMine = false
        ZugZug.ahOnlyMine = false
    end
end

function ZugZug_AH_GetOnlyMine()
    if ZugZug.ahOnlyMine then return true end
    return false
end

function ZugZug_AH_GetSearchLog()
    if not ZugZug.ahSearchLog then return {} end

    local rows = {}
    local outIndex = 1
    local i = 1
    local count = ZugZug_AH_GetContiguousCount(ZugZug.ahSearchLog)
    while i <= count do
        local row = ZugZug.ahSearchLog[i]
        if row then
            rows[outIndex] = row
            outIndex = outIndex + 1
        end
        i = i + 1
    end

    return rows
end

function ZugZug_AH_GetCachedPrice(itemId)
    itemId = tonumber(itemId or 0) or 0
    if itemId <= 0 then return nil end
    if not ZugZug.ahPriceCacheByItemId then return nil end
    local cached = ZugZug.ahPriceCacheByItemId[tostring(itemId)]
    if not cached then return nil end
    if ZugZug_AH_GetOnlyMine() and not ZugZug_AH_IsResultForMe(cached.requester or "") then return nil end
    return cached
end

function ZugZug_AH_ClearResults()
    if not ZugZugDB then ZugZugDB = {} end

    ZugZugDB.ahSearchLog = {}
    ZugZugDB.ahSearchLog.n = 0
    ZugZugDB.ahPriceCacheByItemId = {}

    ZugZug.ahSearchLog = ZugZugDB.ahSearchLog
    ZugZug.ahPriceCacheByItemId = ZugZugDB.ahPriceCacheByItemId
end

local function ZugZug_AH_SendResolvedSearch(query, itemId, itemName, itemLink)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return false end

    query = ZugZug_NormalizeString(query)
    itemId = tonumber(itemId or 0) or 0
    itemName = ZugZug_NormalizeString(itemName or "") or query or ""
    itemLink = itemLink or ""

    if not query or query == "" then query = itemName end
    if not query or query == "" then return false end
    if itemId > 0 and itemLink == "" then itemLink = ZugZug_AH_BuildItemLink(itemId) end

    if itemLink ~= "" then
        local localInfo = ZugZug_AH_ReadItemInfo(itemLink)
        itemName = localInfo.name or itemName
        itemLink = localInfo.link or itemLink
    end

    local body = table.concat({
        ZugZug_SafeEncodeText(query or ""),
        tostring(itemId),
        ZugZug_SafeEncodeText(itemName or query or ""),
        ZugZug_SafeEncodeText(itemLink or ""),
    }, "|")

    ZugZug_BroadcastAddon("AH_SEARCH_REQ~" .. ZugZug_EncodeHexText(body))
    return true
end

function ZugZug_AH_SendSearch(query, itemLink)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return false end

    query = ZugZug_NormalizeString(query)
    itemLink = itemLink or ""

    local info = nil
    if itemLink ~= "" then
        info = ZugZug_AH_GetItemInfoFromLink(itemLink)
    elseif query and query ~= "" and string.find(query, "item:", 1, true) then
        info = ZugZug_AH_GetItemInfoFromLink(query)
    end

    if (not info or not info.itemId or info.itemId <= 0) and query and string.find(query, "^%d+$") then
        info = ZugZug_AH_GetItemInfoFromLink(ZugZug_AH_BuildItemLink(tonumber(query) or 0))
    end

    if info and info.itemId and info.itemId > 0 then
        if (not query or query == "") and info.itemName and info.itemName ~= "" then
            query = info.itemName
        end
        return ZugZug_AH_SendResolvedSearch(query, info.itemId, info.itemName, info.itemLink)
    end

    if query and query ~= "" then
        return ZugZug_AH_SendResolvedSearch(query, 0, "", "", "")
    end

    return false
end

function ZugZug_AH_AddResult(row)
    if not row then return false end
    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.ahSearchLog then ZugZugDB.ahSearchLog = {} end
    if not ZugZugDB.ahPriceCacheByItemId then ZugZugDB.ahPriceCacheByItemId = {} end

    local maxRows = ZugZug.AH_MAX_SEARCH_LOG or 100
    local itemId = tonumber(row.itemId or 0) or 0
    if itemId <= 0 then return false end

    local incomingIsMine = ZugZug_AH_IsResultForMe(row.requester or "")
    local existing = nil
    local existingIndex = nil
    local i = 1
    local count = ZugZug_AH_GetContiguousCount(ZugZugDB.ahSearchLog)

    while i <= count do
        local candidate = ZugZugDB.ahSearchLog[i]
        local existingItemId = 0

        if candidate then
            existingItemId = tonumber(candidate.itemId or 0) or 0
        end

        if candidate and existingItemId == itemId then
            existing = candidate
            existingIndex = i
            break
        end

        i = i + 1
    end

    if ZugZug_AH_GetOnlyMine() and not incomingIsMine then
        if not existing or not ZugZug_AH_IsResultForMe(existing.requester or "") then
            return false
        end
    end

    local finalRow = row
    if existing then
        local existingIsMine = ZugZug_AH_IsResultForMe(existing.requester or "")

        if row.query and row.query ~= "" then
            existing.query = row.query
        end
        existing.itemId = itemId
        if row.itemName and row.itemName ~= "" then
            existing.itemName = row.itemName
        end
        if row.itemLink and row.itemLink ~= "" then
            existing.itemLink = row.itemLink
        end
        existing.minBuyout = row.minBuyout
        existing.avgBuyout = row.avgBuyout
        existing.auctionCount = row.auctionCount
        existing.searchedAt = row.searchedAt

        if incomingIsMine or not existingIsMine then
            existing.requester = row.requester
        end

        finalRow = existing
    else
        finalRow.itemIcon = nil
        finalRow.itemIconSource = nil
    end

    local rebuilt = {}
    local rebuiltIndex = 1
    rebuilt[rebuiltIndex] = finalRow
    rebuiltIndex = rebuiltIndex + 1

    i = 1
    while i <= count do
        local current = ZugZugDB.ahSearchLog[i]
        local currentItemId = 0
        if current then
            currentItemId = tonumber(current.itemId or 0) or 0
        end

        if current and i ~= existingIndex and currentItemId ~= itemId then
            rebuilt[rebuiltIndex] = current
            rebuiltIndex = rebuiltIndex + 1
        end

        i = i + 1
    end

    ZugZug_AH_TrimRowsPreferNonMine(rebuilt)
    ZugZug_ClearTable(ZugZugDB.ahSearchLog)

    i = 1
    while i <= maxRows and rebuilt[i] do
        ZugZugDB.ahSearchLog[i] = rebuilt[i]
        i = i + 1
    end

    ZugZugDB.ahSearchLog.n = ZugZug_AH_GetContiguousCount(ZugZugDB.ahSearchLog)

    ZugZug_ClearTable(ZugZugDB.ahPriceCacheByItemId)
    i = 1
    count = ZugZug_AH_GetContiguousCount(ZugZugDB.ahSearchLog)
    while i <= count do
        local cachedRow = ZugZugDB.ahSearchLog[i]
        if cachedRow and cachedRow.itemId and cachedRow.itemId > 0 then
            ZugZugDB.ahPriceCacheByItemId[tostring(cachedRow.itemId)] = {
                itemId = cachedRow.itemId,
                itemName = cachedRow.itemName,
                itemLink = cachedRow.itemLink,
                itemIcon = cachedRow.itemIcon,
                itemIconSource = cachedRow.itemIconSource,
                minBuyout = cachedRow.minBuyout,
                avgBuyout = cachedRow.avgBuyout,
                auctionCount = cachedRow.auctionCount,
                searchedAt = cachedRow.searchedAt,
                requester = cachedRow.requester,
            }
        end
        i = i + 1
    end

    ZugZug.ahSearchLog = ZugZugDB.ahSearchLog
    ZugZug.ahPriceCacheByItemId = ZugZugDB.ahPriceCacheByItemId
    return true
end

function ZugZug_AH_SetResultFromPayload(payload)
    if not payload or payload == "" then return false end

    local body = ZugZug_DecodeHexText(payload)
    if not body or body == "" then return false end

    local fields = ZugZug_SplitDelimited(body, "|")
    local requester = ZugZug_SafeDecodeText(fields[1] or "")
    local query = ZugZug_SafeDecodeText(fields[2] or "")
    local itemId = tonumber(fields[3] or "0") or 0
    local itemName = ZugZug_SafeDecodeText(fields[4] or "")
    local itemLink = ZugZug_SafeDecodeText(fields[5] or "")
    local minIndex = 6
    if fields[10] then
        minIndex = 7
    end
    local minBuyout = tonumber(fields[minIndex] or "0") or 0
    local avgBuyout = tonumber(fields[minIndex + 1] or "0") or 0
    local auctionCount = tonumber(fields[minIndex + 2] or "0") or 0
    local searchedAt = tonumber(fields[minIndex + 3] or "0") or time()

    if not requester or requester == "" then return false end
    if (not query or query == "") and (not itemName or itemName == "") then return false end
    if itemId <= 0 then return false end
    itemLink = ZugZug_AH_NormalizeResultLink(itemId, itemName, itemLink)

    if itemLink ~= "" then
        local localInfo = ZugZug_AH_ReadItemInfo(itemLink)
        if localInfo.name and localInfo.name ~= "" then
            itemName = localInfo.name
        end
        itemLink = ZugZug_AH_NormalizeResultLink(itemId, itemName, localInfo.link or itemLink)
    end

    local row = {
        requester = requester,
        query = query,
        itemId = itemId,
        itemName = itemName,
        itemLink = itemLink,
        minBuyout = minBuyout,
        avgBuyout = avgBuyout,
        auctionCount = auctionCount,
        searchedAt = searchedAt,
    }

    return ZugZug_AH_AddResult(row)
end

function ZugZug_AH_SetFocusedEdit(edit)
    ZugZug.ahFocusedEdit = edit
end

function ZugZug_AH_SetActiveEdit(edit)
    ZugZug.ahActiveEdit = edit
end

function ZugZug_AH_TryInsertLink(link)
    if not link or link == "" then return false end
    if not ZugZug.UI or ZugZug.UI.activeTab ~= "auction" then return false end
    local edit = ZugZug.ahFocusedEdit or ZugZug.ahActiveEdit
    if not edit then return false end
    if edit.IsVisible and not edit:IsVisible() then return false end

    local info = ZugZug_AH_GetItemInfoFromLink(link)
    if not info or not info.itemId or info.itemId <= 0 then return false end
    if not info.itemName or info.itemName == "" then return false end

    edit.ahSettingText = true
    edit:SetText(info.itemName)
    edit.ahSettingText = nil
    edit.ahItemLink = info.itemLink or link
    edit.ahItemId = info.itemId or 0
    return true
end

local function ZugZug_AH_GetLocalIconFromLink(link)
    if not link or link == "" then return "" end

    local localInfo = ZugZug_AH_ReadItemInfo(link)
    local icon = ZugZug_AH_NormalizeIcon(localInfo.texture or "")
    if icon and icon ~= "" then
        return icon
    end

    return ""
end

function ZugZug_AH_GetLocalIcon(row)
    if not row then return "" end

    local itemIcon = ""
    if row.itemIconSource == "local" then
        itemIcon = ZugZug_AH_NormalizeIcon(row.itemIcon or "")
    end
    if itemIcon and itemIcon ~= "" then
        return itemIcon
    end

    local localIcon = ""
    local itemId = tonumber(row.itemId or 0) or 0
    if itemId > 0 then
        localIcon = ZugZug_AH_GetLocalIconFromLink(ZugZug_AH_BuildItemLink(itemId))
    end

    local itemLink = row.itemLink or ""
    if (not localIcon or localIcon == "") and itemLink and itemLink ~= "" then
        localIcon = ZugZug_AH_GetLocalIconFromLink(itemLink)
    end

    if localIcon and localIcon ~= "" then
        row.itemIcon = localIcon
        row.itemIconSource = "local"

        if ZugZugDB and ZugZugDB.ahPriceCacheByItemId and itemId > 0 then
            local cached = ZugZugDB.ahPriceCacheByItemId[tostring(itemId)]
            if cached then
                cached.itemIcon = localIcon
                cached.itemIconSource = "local"
            end
        end

        return localIcon
    end

    return ""
end

local function ZugZug_AH_AddTooltipLines(tooltip, link)
    if not tooltip or not link then return end

    local itemId = ZugZug_AH_GetItemIdFromLink(link)
    local cached = ZugZug_AH_GetCachedPrice(itemId)
    if not cached then return end

    tooltip:AddLine(" ")
    tooltip:AddLine("|cff69ccf0AH Min Buyout:|r " .. ZugZug_AH_FormatCopper(cached.minBuyout or 0), 1, 1, 1)
    tooltip:AddLine("|cff69ccf0AH Avg Buyout:|r " .. ZugZug_AH_FormatCopper(cached.avgBuyout or 0), 1, 1, 1)
    tooltip:AddLine("|cff69ccf0AH Listings:|r " .. tostring(cached.auctionCount or 0), 1, 1, 1)
    tooltip:Show()
end

local function ZugZug_AH_TryInsertContainerItem(bag, slot)
    if not IsShiftKeyDown or not IsShiftKeyDown() then return false end
    if not ZugZug.UI or ZugZug.UI.activeTab ~= "auction" then return false end
    if not GetContainerItemLink then return false end

    bag = tonumber(bag or 0)
    slot = tonumber(slot or 0)
    if not bag or not slot then return false end

    local link = GetContainerItemLink(bag, slot)
    if link and ZugZug_AH_TryInsertLink and ZugZug_AH_TryInsertLink(link) then
        return true
    end

    return false
end

local function ZugZug_AH_GetContainerSlotFromButton(button)
    local frame = button or this
    if not frame then return nil, nil end
    if type(frame) ~= "table" and type(frame) ~= "userdata" then return nil, nil end

    local slot = nil
    if frame.GetID then
        slot = frame:GetID()
    end

    local parent = nil
    if frame.GetParent then
        parent = frame:GetParent()
    end

    local bag = nil
    if parent and parent.GetID then
        bag = parent:GetID()
    end

    return bag, slot
end

function ZugZug_AH_HookTooltips()
    if ZugZug.ahHooksInstalled then return end
    ZugZug.ahHooksInstalled = true

    if ChatEdit_InsertLink then
        ZugZug.ahOriginalChatEditInsertLink = ChatEdit_InsertLink
        ChatEdit_InsertLink = function(link)
            if ZugZug_AH_TryInsertLink and ZugZug_AH_TryInsertLink(link) then
                return true
            end

            return ZugZug.ahOriginalChatEditInsertLink(link)
        end
    end

    if HandleModifiedItemClick then
        ZugZug.ahOriginalHandleModifiedItemClick = HandleModifiedItemClick
        HandleModifiedItemClick = function(link)
            if IsShiftKeyDown and IsShiftKeyDown() and ZugZug_AH_TryInsertLink and ZugZug_AH_TryInsertLink(link) then
                return true
            end

            return ZugZug.ahOriginalHandleModifiedItemClick(link)
        end
    end

    if UseContainerItem then
        ZugZug.ahOriginalUseContainerItem = UseContainerItem
        UseContainerItem = function(bag, slot, onSelf)
            if ZugZug_AH_TryInsertContainerItem(bag, slot) then
                return
            end

            return ZugZug.ahOriginalUseContainerItem(bag, slot, onSelf)
        end
    end

    if PickupContainerItem then
        ZugZug.ahOriginalPickupContainerItem = PickupContainerItem
        PickupContainerItem = function(bag, slot)
            if ZugZug_AH_TryInsertContainerItem(bag, slot) then
                return
            end

            return ZugZug.ahOriginalPickupContainerItem(bag, slot)
        end
    end

    if ContainerFrameItemButton_OnClick then
        ZugZug.ahOriginalContainerFrameItemButtonOnClick = ContainerFrameItemButton_OnClick
        ContainerFrameItemButton_OnClick = function(button, ignoreShift)
            local bag, slot = ZugZug_AH_GetContainerSlotFromButton(this)
            if not bag or not slot then
                bag, slot = ZugZug_AH_GetContainerSlotFromButton(button)
            end
            if ZugZug_AH_TryInsertContainerItem(bag, slot) then
                return
            end

            return ZugZug.ahOriginalContainerFrameItemButtonOnClick(button, ignoreShift)
        end
    end

    if ContainerFrameItemButton_OnModifiedClick then
        ZugZug.ahOriginalContainerFrameItemButtonOnModifiedClick = ContainerFrameItemButton_OnModifiedClick
        ContainerFrameItemButton_OnModifiedClick = function(button)
            local bag, slot = ZugZug_AH_GetContainerSlotFromButton(this)
            if not bag or not slot then
                bag, slot = ZugZug_AH_GetContainerSlotFromButton(button)
            end
            if ZugZug_AH_TryInsertContainerItem(bag, slot) then
                return true
            end

            return ZugZug.ahOriginalContainerFrameItemButtonOnModifiedClick(button)
        end
    end

    if GameTooltip and GameTooltip.SetHyperlink then
        ZugZug.ahOriginalTooltipSetHyperlink = GameTooltip.SetHyperlink
        GameTooltip.SetHyperlink = function(self, link)
            local result = ZugZug.ahOriginalTooltipSetHyperlink(self, link)
            ZugZug_AH_AddTooltipLines(self, link)
            return result
        end
    end

    if GameTooltip and GameTooltip.SetBagItem then
        ZugZug.ahOriginalTooltipSetBagItem = GameTooltip.SetBagItem
        GameTooltip.SetBagItem = function(self, bag, slot)
            local result = ZugZug.ahOriginalTooltipSetBagItem(self, bag, slot)
            if GetContainerItemLink then
                ZugZug_AH_AddTooltipLines(self, GetContainerItemLink(bag, slot))
            end
            return result
        end
    end
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
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end

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

function ZugZug_BroadcastAddon(msg)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end
    ZugZug_SendAddon(msg, "GUILD")
end

function ZugZug_SendBotWhisper(msg)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end
    SendChatMessage(ZugZug.PREFIX .. "~" .. msg, "WHISPER", nil, ZugZug.BOTNAME)
end

function ZugZug_SendBotCommand(command)
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end
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

local function ZugZug_CountIncomingChunks()
    local count = 0

    for key in pairs(ZugZug.incomingChunks) do
        count = count + 1
    end

    return count
end

local function ZugZug_TrimIncomingChunks()
    local max = tonumber(ZugZug.MAX_INCOMING_CHUNKS or 80) or 80
    local count = ZugZug_CountIncomingChunks()

    if max < 1 then
        max = 1
    end

    while count >= max do
        local oldestKey = nil
        local oldestAt = nil

        for key, entry in pairs(ZugZug.incomingChunks) do
            local created = 0

            if entry and entry.created then
                created = tonumber(entry.created) or 0
            end

            if not oldestKey or created < oldestAt then
                oldestKey = key
                oldestAt = created
            end
        end

        if not oldestKey then
            return
        end

        ZugZug.incomingChunks[oldestKey] = nil
        count = count - 1
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
        ZugZug_TrimIncomingChunks()

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

function ZugZug_SetRosterWithinMyLevelOnly(enabled)
    if not ZugZugDB then ZugZugDB = {} end
    if enabled then
        ZugZugDB.rosterWithinMyLevelOnly = true
        ZugZug.rosterWithinMyLevelOnly = true
    else
        ZugZugDB.rosterWithinMyLevelOnly = false
        ZugZug.rosterWithinMyLevelOnly = false
    end
end

function ZugZug_IsRosterWithinMyLevelOnly()
    if ZugZug.rosterWithinMyLevelOnly then return true end
    return false
end

function ZugZug_GetNameKey(name)
    local text = tostring(name or "")
    local dash = string.find(text, "-", 1, true)

    if dash then
        text = string.sub(text, 1, dash - 1)
    end

    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")

    if text == "" then
        return nil
    end

    return string.lower(text)
end

function ZugZug_UpdateFriendCache(requestRefresh)
    if not ZugZug.friendsByName then
        ZugZug.friendsByName = {}
    else
        ZugZug_ClearTable(ZugZug.friendsByName)
    end

    if requestRefresh and ShowFriends then
        ShowFriends()
    end

    if not GetNumFriends or not GetFriendInfo then
        return
    end

    local friendCount = GetNumFriends() or 0
    local i = 1

    while i <= friendCount do
        local name = GetFriendInfo(i)
        local key = ZugZug_GetNameKey(name)

        if key then
            ZugZug.friendsByName[key] = true
        end

        i = i + 1
    end
end

function ZugZug_IsFriend(name)
    if not ZugZug.friendsByName then
        return false
    end

    local key = ZugZug_GetNameKey(name)

    if key and ZugZug.friendsByName[key] then
        return true
    end

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

        local aFriend = false
        local bFriend = false
        if a and a.isFriend then aFriend = true end
        if b and b.isFriend then bFriend = true end
        if aFriend ~= bFriend then
            return aFriend
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
    if not ZugZug.onlineMembers then
        ZugZug.onlineMembers = {}
        ZugZug.onlineMembers.n = 0
    else
        ZugZug_ClearTable(ZugZug.onlineMembers)
    end

    if not IsInGuild() then return end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return end
    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.classByName then ZugZugDB.classByName = {} end
    ZugZug.classByName = ZugZugDB.classByName

    if ZugZug_UpdateFriendCache then
        ZugZug_UpdateFriendCache()
    end

    local numMembers = GetNumGuildMembers()
    if not numMembers then return end

    local i = 1
    local onlineIndex = 1

    while i <= numMembers do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online = GetGuildRosterInfo(i)
        if name and class and class ~= "" then
            ZugZug_SaveClassForName(name, class)
        end
        if online and name and string.lower(name) ~= string.lower(ZugZug.BOTNAME) then
            ZugZug.onlineMembers[onlineIndex] = {
                name = name,
                class = class,
                rank = rank,
                rankIndex = rankIndex,
                level = level,
                zone = zone,
                isFriend = ZugZug_IsFriend and ZugZug_IsFriend(name),
            }
            onlineIndex = onlineIndex + 1
        end
        i = i + 1
    end

    ZugZug.onlineMembers.n = onlineIndex - 1
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
    if not IsInGuild or not IsInGuild() then
        ZugZug_DisableForNonGuild()
        ZugZug_Log("You are not in a guild! Join |cff00ff00<" .. ZugZug.GUILD_NAME .. ">|r to use this addon.")
        return false
    end

    local guildName, guildRank, guildRankIndex = GetGuildInfo("player")
    if guildName == ZugZug.GUILD_NAME then
        guildRank = guildRank or "Guildie"
        ZugZug.READY = true

        if GuildRoster then GuildRoster() end
        ZugZug_RecordAddonUser(UnitName("player"), ZugZug.VERSION)
        ZugZug_UpdateOnlineMembers()
        ZugZug_Log("Welcome back, |cff00ff00" .. guildRank .. "|r " .. ZugZug_ClassColorize(UnitName("player")) .. "!")
        ZugZug_Log("You are a proud member of |cff00ff00<" .. guildName .. ">|r.")
        if guildRankIndex and guildRankIndex <= 2 then
            ZugZug_Log("|cff00ffffOfficer|r access granted.")
        end
        ZugZug_BroadcastAddon("LOGIN~" .. ZugZug.VERSION)
        if ZugZug_StartVersionGossip then
            ZugZug_StartVersionGossip()
        end
        if ZugZug_LFG_RequestSync then
            ZugZug_LFG_RequestSync()
        end
        return true
    else
        ZugZug_DisableForNonGuild()
        ZugZug_Log("Unfortunately you are not a member of |cff00ff00<" .. ZugZug.GUILD_NAME .. ">|r. Sorry you're lame.")
        return false
    end
end

function ZugZug_StartVersionGossip()
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end

    if ZugZug.versionGossipTicker then
        ZugZug.versionGossipTicker:SetScript("OnUpdate", nil)
        ZugZug.versionGossipTicker = nil
    end

    local frame = CreateFrame("Frame")
    frame.elapsed = 0
    frame.nextAt = 1
    frame.sent = 0

    frame:SetScript("OnUpdate", function()
        if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then
            this:SetScript("OnUpdate", nil)
            ZugZug.versionGossipTicker = nil
            return
        end

        this.elapsed = (this.elapsed or 0) + arg1

        if this.elapsed < (this.nextAt or 1) then
            return
        end

        ZugZug_BroadcastAddon("VERSION~" .. ZugZug.VERSION)
        this.sent = (this.sent or 0) + 1

        if this.sent >= 3 then
            this:SetScript("OnUpdate", nil)
            ZugZug.versionGossipTicker = nil
            return
        end

        this.nextAt = this.nextAt + 2
    end)

    ZugZug.versionGossipTicker = frame
end

function ZugZug_MaybeReplyVersionGossip()
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end

    local now = GetTime()
    if ZugZug.lastVersionGossipReplyAt and now - ZugZug.lastVersionGossipReplyAt < 4 then
        return
    end

    ZugZug.lastVersionGossipReplyAt = now
    ZugZug_BroadcastAddon("VERSION~" .. ZugZug.VERSION)
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

    local currentContinent = nil
    local currentZone = nil

    if GetCurrentMapContinent then
        currentContinent = GetCurrentMapContinent()
    end

    if GetCurrentMapZone then
        currentZone = GetCurrentMapZone()
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

    return mapFile, zone, x, y, currentContinent, currentZone
end

function ZugZug_BroadcastMyLocation()
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end
    if not ZugZug_GetShareMyLocation or not ZugZug_GetShareMyLocation() then return end

    local mapFile, zone, x, y, continent, zoneIndex = ZugZug_GetMyMapPositionSafe()

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
        .. tostring(time()) .. ":"
        .. tostring(continent or 0) .. ":"
        .. tostring(zoneIndex or 0)
    )
end

function ZugZug_SetGuildLocationFromPayload(sender, payload)
    if not sender or sender == "" then return end
    if sender == UnitName("player") then return end
    if not payload or payload == "" then return end

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
    local continent = tonumber(parts[7] or "0") or 0
    local zoneIndex = tonumber(parts[8] or "0") or 0

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
        continent = continent,
        zoneIndex = zoneIndex,
    }
end

function ZugZug_FindGuildLocation(name)
    if not name or name == "" then return nil end
    if not ZugZug.guildLocations then return nil end

    ZugZug_PruneGuildLocations()

    local wanted = string.lower(name)

    for locName, loc in pairs(ZugZug.guildLocations) do
        if locName and loc and string.lower(locName) == wanted then
            return loc
        end
    end

    return nil
end

function ZugZug_ShowGuildLocation(name)
    local loc = ZugZug_FindGuildLocation(name)

    if not loc then
        ZugZug_Log("Cannot find " .. tostring(name or "") .. ".")
        return false
    end

    if WorldMapFrame and not WorldMapFrame:IsShown() then
        if ToggleWorldMap then
            ToggleWorldMap()
        elseif ShowUIPanel then
            ShowUIPanel(WorldMapFrame)
        else
            WorldMapFrame:Show()
        end
    end

    if loc.continent and loc.zoneIndex and loc.continent > 0 and loc.zoneIndex > 0 and SetMapZoom then
        SetMapZoom(loc.continent, loc.zoneIndex)
    end

    if ZugZug_Map_UpdateGuildPins then
        ZugZug_Map_UpdateGuildPins()
    end

    if ZugZug_Wait and ZugZug_Map_UpdateGuildPins then
        ZugZug_Wait(0.1, function()
            if loc.continent and loc.zoneIndex and loc.continent > 0 and loc.zoneIndex > 0 and SetMapZoom then
                SetMapZoom(loc.continent, loc.zoneIndex)
            end

            ZugZug_Map_UpdateGuildPins()
        end)
    end

    return true
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
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end
    if ZugZug.locationTicker then return end

    local frame = CreateFrame("Frame")
    frame.lastBroadcast = 0
    frame.lastPinUpdate = 0

    frame:SetScript("OnUpdate", function()
        if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then
            return
        end

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
    if not ZugZug.READY or not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then return end

    local msg = "<" .. ZugZug.GUILD_NAME .. ">! English guild LFM! Previously 4k+ on Turtle, rebuilding here!"
        .. " Custom in-game NPC, Discord lvl tracking, custom tools, and more! Whisper 'inv' to " .. ZugZug.BOTNAME
        .. " for an invite. Join our Discord @ " .. ZugZug.DISCORD .. " !"
    local id = GetChannelName("English")
    if id and id > 0 then SendChatMessage(msg, "CHANNEL", nil, id) end
end
