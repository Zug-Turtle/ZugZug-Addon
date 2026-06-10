-- Slash Commands
local function ZugZug_ShowHelp()
    ZugZug_Log("Commands:")
    ZugZug_Log("|cff00ffff/zug|r - Toggle Guild UI")
    ZugZug_Log("|cff00ffff/zug see [name]|r - Show a guildie's last shared map location")
    ZugZug_Log("|cff00ffff/zug help|r - Show commands")
end

local function ZugZug_CountTableValues(t)
    local count = 0

    if not t then
        return count
    end

    for key, value in pairs(t) do
        if value then
            count = count + 1
        end
    end

    return count
end

local function ZugZug_GetLuaKB()
    if gcinfo then
        return gcinfo()
    end

    if collectgarbage then
        return collectgarbage("count")
    end

    return 0
end

local function ZugZug_ShowPerf()
    local onlineCount = 0
    local lfgCount = 0
    local chunkCount = ZugZug_CountTableValues(ZugZug.incomingChunks)
    local tabCount = 0
    local pageCount = 0
    local refreshCount = 0

    if ZugZug_GetOnlineMemberCount then
        onlineCount = ZugZug_GetOnlineMemberCount()
    end

    if ZugZug_LFG_GetListingCount then
        lfgCount = ZugZug_LFG_GetListingCount()
    end

    if ZugZug.UI then
        if ZugZug.UI.tabs then
            tabCount = table.getn(ZugZug.UI.tabs)
        end
        pageCount = ZugZug_CountTableValues(ZugZug.UI.pages)
        refreshCount = ZugZug.UI.refreshCount or 0
    end

    local refs = tabCount + pageCount + onlineCount + lfgCount + chunkCount
    local luaKB = ZugZug_GetLuaKB()
    local luaRounded = math.floor((tonumber(luaKB) or 0) + 0.5)

    ZugZug_Log("perf refs=" .. tostring(refs)
        .. " online=" .. tostring(onlineCount)
        .. " lfg=" .. tostring(lfgCount)
        .. " chunks=" .. tostring(chunkCount)
        .. " refreshes=" .. tostring(refreshCount)
        .. " luaKB=" .. tostring(luaRounded)
    )
end

local function ZugZug_IsReadyGuildMember()
    if ZugZug_IsGuildAllowed and ZugZug_IsGuildAllowed() then
        return ZugZug.READY
    end

    if ZugZug_DisableForNonGuild then
        ZugZug_DisableForNonGuild()
    end

    return false
end

local function ZugZug_BlockNonGuildCommand()
    if ZugZug_IsReadyGuildMember() then
        return false
    end

    ZugZug_Log("ZugZug is only available to |cff00ff00<" .. ZugZug.GUILD_NAME .. ">|r guild members.")
    return true
end

local function ZugZug_OnSlashCommand(msg)
    local cmd, args = ZugZug_ParseCommand(msg)

    if ZugZug_BlockNonGuildCommand() then return end

    if cmd == "" then ZugZug_UI_Toggle() return end
    if cmd == "perf" then ZugZug_ShowPerf() return end
    if cmd == "see" then
        local name = ZugZug_NormalizeString(args or "")
        if not name then
            ZugZug_Log("Usage: |cff00ffff/zug see [name]|r")
            return
        end
        if ZugZug_ShowGuildLocation then
            ZugZug_ShowGuildLocation(name)
        else
            ZugZug_Log("Cannot find " .. name .. ".")
        end
        return
    end
    if cmd == "help" or cmd == "?" then ZugZug_ShowHelp() return end


    ZugZug_Log("Unknown command: " .. cmd)
    ZugZug_ShowHelp()
    return
end

SLASH_ZUGZUG1 = "/zug"
SLASH_ZUGZUG2 = "/zz"
SlashCmdList["ZUGZUG"] = function(msg) ZugZug_OnSlashCommand(msg) return end

-- Addon Messages
local function ZugZug_OnAddonMessage()
    local prefix = arg1
    local message = arg2
    local channel = arg3
    local sender = arg4

    if sender == UnitName("player") then return end
    if not prefix or prefix ~= ZugZug.PREFIX then return end
    if not message or message == "" then return end
    if not ZugZug_IsReadyGuildMember() then return end

    message = ZugZug_RebuildIncomingMessage(message, sender)
    if not message then return end

    local sep = string.find(message, "~", 1, true)
    if not sep then return end

    local cmd = string.upper(string.sub(message, 1, sep - 1))
    local data = string.sub(message, sep + 1)

    if cmd == "LOGIN" then
        ZugZug_RecordAddonUser(sender, data)
        if ZugZug_LFG_RespondToSyncRequest then
            ZugZug_LFG_RespondToSyncRequest(sender)
        end
        if ZugZug_LFG_SyncToGuild then
            ZugZug_LFG_SyncToGuild()
        end
        if ZugZug.UI and ZugZug.UI.activeTab == "guild" then
            if ZugZug_UI_UpdateActiveTabThrottled then
                ZugZug_UI_UpdateActiveTabThrottled("addon_login", 0.25)
            else
                ZugZug_UI_UpdateTab("guild", "addon_login")
            end
        end
        return
    end

    if cmd == "VERSION" then
        ZugZug_RecordAddonUser(sender, data)
        if ZugZug_MaybeReplyVersionGossip then
            ZugZug_MaybeReplyVersionGossip()
        end
        if ZugZug.UI and ZugZug.UI.activeTab == "guild" then
            if ZugZug_UI_UpdateActiveTabThrottled then
                ZugZug_UI_UpdateActiveTabThrottled("addon_version", 0.25)
            else
                ZugZug_UI_UpdateTab("guild", "addon_version")
            end
        end
        return
    end

    if cmd == "NOTICE" then
        if sender == ZugZug.BOTNAME then
            local sep = string.find(data or "", ":", 1, true)
            if sep then
                local target = ZugZug_SafeDecodeText(string.sub(data, 1, sep - 1))
                local notice = ZugZug_SafeDecodeText(string.sub(data, sep + 1))
                if target and string.lower(target) == string.lower(UnitName("player") or "") and notice and notice ~= "" then
                    ZugZug_Log(notice)
                end
            end
        end
        return
    end

    if cmd == "CAPS" then
        if sender == ZugZug.BOTNAME then
            local sep = string.find(data or "", ":", 1, true)
            if sep then
                local target = ZugZug_SafeDecodeText(string.sub(data, 1, sep - 1))
                local caps = string.sub(data, sep + 1)
                if target and string.lower(target) == string.lower(UnitName("player") or "") then
                    local ahEnabled = nil
                    if string.find(caps or "", "AH=1", 1, true) then
                        ahEnabled = true
                    elseif string.find(caps or "", "AH=0", 1, true) then
                        ahEnabled = false
                    end
                    if ahEnabled ~= nil and ZugZug_UI_SetAuctionTabEnabled then
                        ZugZug_UI_SetAuctionTabEnabled(ahEnabled)
                    end
                end
            end
        end
        return
    end

    if cmd == "STATE" then
        if sender == ZugZug.BOTNAME then
            ZugZug_SetDashboardStateFromPayload(data)
            if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                ZugZug_UI_UpdateTab("dashboard", "state")
            end
        end
        return
    end

    if cmd == "IDENTITY" then
        if sender == ZugZug.BOTNAME and ZugZug_SetDashboardIdentityFromPayload then
            if ZugZug_SetDashboardIdentityFromPayload(data) then
                if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                    ZugZug_UI_UpdateTab("dashboard", "identity")
                end
            end
        end
        return
    end

    if cmd == "CAPY_CHAT" then
        if sender == ZugZug.BOTNAME and ZugZug_AddCapyChatFromPayload then
            if ZugZug_AddCapyChatFromPayload(data) then
                if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                    ZugZug_UI_UpdateTab("dashboard", "capy_chat")
                end
            end
        end
        return
    end

    if cmd == "CAPY_CHAT_SEND" then
        if ZugZug_AddCapyChatFromSendPayload then
            if ZugZug_AddCapyChatFromSendPayload(sender, data) then
                if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                    ZugZug_UI_UpdateTab("dashboard", "capy_chat")
                end
            end
        end
        return
    end

    if cmd == "AH_SEARCH_RESULT" then
        if sender == ZugZug.BOTNAME and ZugZug_AH_SetResultFromPayload then
            if ZugZug_AH_SetResultFromPayload(data) then
                if ZugZug.UI and ZugZug.UI.activeTab == "auction" then
                    ZugZug_UI_UpdateTab("auction", "ah_result")
                end
            end
        end
        return
    end

    if cmd == "LOC" then
        ZugZug_SetGuildLocationFromPayload(sender, data)

        if WorldMapFrame and WorldMapFrame:IsShown() then
            ZugZug_Map_UpdateGuildPins()
        end

        return
    end

    if string.find(cmd, "OFC_", 1, true) == 1 then
        if cmd == "OFC_BANLIST" then
            ZugZug_SetBanlistFromPayload(data)
            if ZugZug.UI and ZugZug.UI.activeTab == "officer" then
                ZugZug_UI_UpdateTab("officer", "banlist")
            end
            return
        end

        if cmd == "OFC_NOTICE" then
            ZugZug_Log(ZugZug_SafeDecodeText(data or ""))
            if ZugZug.UI and ZugZug.UI.activeTab == "officer" then
                ZugZug_UI_UpdateTab("officer", "notice")
            end
            return
        end
        return
    end

    if string.find(cmd, "LFG_", 1, true) == 1 then
        if ZugZug_LFG_HandleMessage then
            ZugZug_LFG_HandleMessage(cmd, data, sender)
            if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                if ZugZug_UI_UpdateActiveTabThrottled then
                    ZugZug_UI_UpdateActiveTabThrottled("lfg_dashboard", 0.25)
                else
                    ZugZug_UI_UpdateTab("dashboard", "lfg_dashboard")
                end
            end
        end
        return
    end
end

-- Main Event Frame
local function ZugZug_RefreshDashboardMOTD(throttleReason)
    local changed = false

    if ZugZug_UpdateDashboardMOTDFromGuild then
        changed = ZugZug_UpdateDashboardMOTDFromGuild()
    end

    if changed and ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
        if throttleReason and ZugZug_UI_UpdateActiveTabThrottled then
            ZugZug_UI_UpdateActiveTabThrottled(throttleReason, 0.25)
        elseif ZugZug_UI_UpdateActiveTab then
            ZugZug_UI_UpdateActiveTab("motd")
        else
            ZugZug_UI_UpdateTab("dashboard", "motd")
        end
    end

    return changed
end

local function ZugZug_RunGuildStartup()
    if ZugZug.guildStartupComplete then
        return ZugZug_IsReadyGuildMember()
    end

    if ZugZug.guildStartupRunning then
        return ZugZug.READY
    end

    ZugZug.guildStartupRunning = true

    if not ZugZug_HandleLogin() then
        ZugZug.guildStartupRunning = false
        return false
    end

    ZugZug_UI_RegisterDefaultTabs()
    ZugZug_UI_CreateMinimapButton()
    if ZugZug_UpdateFriendCache then
        ZugZug_UpdateFriendCache(true)
    end
    if ZugZug_AH_HookTooltips then
        ZugZug_AH_HookTooltips()
    end

    ZugZug_RefreshDashboardMOTD()
    ZugZug_LFG_StartTicker()

    if ZugZug_Location_StartTicker then
        ZugZug_Location_StartTicker()
    end

    if ZugZug_GetShowWindowOnLogin and ZugZug_GetShowWindowOnLogin() then
        ZugZug_UI_Show()
    end

    ZugZug.guildStartupComplete = true
    ZugZug.guildStartupRunning = false
    return true
end

local zug = CreateFrame("Frame")
zug:RegisterEvent("PLAYER_LOGIN")
zug:RegisterEvent("PLAYER_LOGOUT")
zug:RegisterEvent("VARIABLES_LOADED")
zug:RegisterEvent("CHAT_MSG_ADDON")
zug:RegisterEvent("CHAT_MSG_SYSTEM")
zug:RegisterEvent("CHAT_MSG_GUILD")
zug:RegisterEvent("CHAT_MSG_OFFICER")
zug:RegisterEvent("GUILD_ROSTER_UPDATE")
zug:RegisterEvent("ZONE_CHANGED")
zug:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zug:RegisterEvent("ZONE_CHANGED_INDOORS")
zug:RegisterEvent("PARTY_INVITE_REQUEST")
zug:RegisterEvent("PARTY_MEMBERS_CHANGED")
zug:RegisterEvent("RAID_ROSTER_UPDATE")
pcall(function()
    zug:RegisterEvent("FRIENDLIST_UPDATE")
end)
pcall(function()
    zug:RegisterEvent("PLAYER_GUILD_UPDATE")
end)
pcall(function()
    zug:RegisterEvent("GUILD_MOTD")
end)

if ZugZug_UI_CreateMinimapButton then
    ZugZug_UI_CreateMinimapButton()
end

zug:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        ZugZug_InitDB()
        if ZugZug_UI_CreateMinimapButton then
            ZugZug_UI_CreateMinimapButton()
        end
    elseif event == "PLAYER_GUILD_UPDATE" then
        if not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then
            if ZugZug_DisableForNonGuild then
                ZugZug_DisableForNonGuild()
            end
            return
        end

        if not ZugZug.READY and not ZugZug.guildStartupComplete then
            ZugZug_RunGuildStartup()
        end
    elseif event == "GUILD_ROSTER_UPDATE" then 
        if not ZugZug_IsGuildAllowed or not ZugZug_IsGuildAllowed() then
            if ZugZug_DisableForNonGuild then
                ZugZug_DisableForNonGuild()
            end
            return
        end

        if not ZugZug.READY then
            if not ZugZug.guildStartupComplete then
                ZugZug_RunGuildStartup()
            end
            return
        end

        ZugZug_RefreshDashboardMOTD("guild_roster_motd")
        ZugZug_UpdateOnlineMembers()
        if ZugZug_LFG_PruneOffline then
            ZugZug_LFG_PruneOffline()
        end

        if ZugZug_UI_UpdateActiveTabThrottled then
            ZugZug_UI_UpdateActiveTabThrottled("guild_roster", 0.25)
        end
    elseif event == "FRIENDLIST_UPDATE" then
        if not ZugZug_IsReadyGuildMember() then return end
        if ZugZug_UpdateFriendCache then
            ZugZug_UpdateFriendCache()
        end
        if ZugZug_UpdateOnlineMembers then
            ZugZug_UpdateOnlineMembers()
        end
        if ZugZug.UI and ZugZug.UI.activeTab == "guild" then
            if ZugZug_UI_UpdateActiveTabThrottled then
                ZugZug_UI_UpdateActiveTabThrottled("friendlist", 0.25)
            else
                ZugZug_UI_UpdateTab("guild", "friendlist")
            end
        end
    elseif event == "PLAYER_LOGIN" then
        ZugZug_Wait(1, function()
            ZugZug_RunGuildStartup()
        end)
    elseif event == "GUILD_MOTD" then
        if not ZugZug_IsReadyGuildMember() then return end
        ZugZug_RefreshDashboardMOTD()
    elseif event == "PLAYER_LOGOUT" then
        return
    elseif event == "CHAT_MSG_ADDON" then
        if not ZugZug_IsReadyGuildMember() then return end
        ZugZug_OnAddonMessage()

    elseif event == "CHAT_MSG_GUILD" then
        if not ZugZug_IsReadyGuildMember() then return end
        local msg = arg1
        local sender = arg2
        if sender and msg then
            ZugZug_AddGuildChatLog(sender, msg)
        end
    elseif event == "CHAT_MSG_OFFICER" then
        if not ZugZug_IsReadyGuildMember() then return end
        local msg = arg1
        local sender = arg2

        if sender and msg then
            ZugZug_AddOfficerChatLog(sender, msg)

        if ZugZug.UI and ZugZug.UI.activeTab == "officer" then
                ZugZug_UI_UpdateTab("officer", "officer_chat")
        end
        end
    elseif event == "PARTY_INVITE_REQUEST" then
        if not ZugZug_IsReadyGuildMember() then return end
        if ZugZug_LFG_HandlePartyInvite then
            ZugZug_LFG_HandlePartyInvite(arg1)
        end
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        if not ZugZug_IsReadyGuildMember() then return end
        if ZugZug_LFG_OnPartyChanged then
            ZugZug_LFG_OnPartyChanged()
        end
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
        if not ZugZug_IsReadyGuildMember() then return end
        if ZugZug.UI and ZugZug.UI.activeTab == "guild" then
            if ZugZug_UI_UpdateActiveTabThrottled then
                ZugZug_UI_UpdateActiveTabThrottled("zone_changed", 0.25)
            else
                ZugZug_UI_UpdateTab("guild", "zone_changed")
            end
        end
    end
end)
