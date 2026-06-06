-- Slash Commands
local function ZugZug_ShowHelp()
    ZugZug_Log("Commands:")
    ZugZug_Log("|cff00ffff/zug|r - Toggle Guild UI")
    ZugZug_Log("|cff00ffff/zug help|r - Show commands")
end

local function ZugZug_OnSlashCommand(msg)
    local cmd, args = ZugZug_ParseCommand(msg)

    if cmd == "" then ZugZug_UI_Toggle() return end
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

    message = ZugZug_RebuildIncomingMessage(message, sender)
    if not message then return end

    local sep = string.find(message, "~", 1, true)
    if not sep then return end

    local cmd = string.upper(string.sub(message, 1, sep - 1))
    local data = string.sub(message, sep + 1)

    if cmd == "LOGIN" then
        ZugZug_RecordAddonUser(sender, data)
        if ZugZug_LFG_SyncToGuild then
            ZugZug_LFG_SyncToGuild()
        end
        if ZugZug.UI and ZugZug.UI.activeTab == "guild" then
            ZugZug_UI_ShowTab("guild")
        end
        return
    end

    if cmd == "STATE" then
        if sender == ZugZug.BOTNAME then
            ZugZug_SetDashboardStateFromPayload(data)
            if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                ZugZug_UI_ShowTab("dashboard")
            end
        end
        return
    end

    if string.find(cmd, "OFC_", 1, true) == 1 then
        if cmd == "OFC_BANLIST" then
            ZugZug_SetBanlistFromPayload(data)
            if ZugZug.UI and ZugZug.UI.activeTab == "officer" then
                ZugZug_UI_ShowTab("officer")
            end
            return
        end

        if cmd == "OFC_NOTICE" then
            ZugZug_Log(ZugZug_SafeDecodeText(data or ""))
            if ZugZug.UI and ZugZug.UI.activeTab == "officer" then
                ZugZug_UI_ShowTab("officer")
            end
            return
        end
        return
    end

    if string.find(cmd, "LFG_", 1, true) == 1 then
        if ZugZug_LFG_HandleMessage then
            ZugZug_LFG_HandleMessage(cmd, data, sender)
            if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                ZugZug_UI_ShowTab("dashboard")
            end
        end
        return
    end
end

-- Main Event Frame
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

zug:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        ZugZug_InitDB()
        ZugZug_UI_CreateMinimapButton()
        -- Handle ZugZugDB Lua SavedVariables later when we need it :p
    elseif event == "GUILD_ROSTER_UPDATE" then 
        ZugZug_UpdateOnlineMembers()
        if ZugZug_LFG_PruneOffline then
            ZugZug_LFG_PruneOffline()
        end

        if ZugZug.UI and ZugZug.UI.activeTab == "lfg" then
            ZugZug_UI_ShowTab("lfg")
        end
        if ZugZug.UI and ZugZug.UI.activeTab == "guild" then
            ZugZug_UI_ShowTab("guild")
        end
        if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
            ZugZug_UI_ShowTab("dashboard")
        end
    elseif event == "PLAYER_LOGIN" then
        ZugZug_Wait(1, function() 
            ZugZug_HandleLogin()
            ZugZug_UI_RegisterDefaultTabs()
            ZugZug_LFG_StartTicker()

            if ZugZug_GetShowWindowOnLogin and ZugZug_GetShowWindowOnLogin() then
                ZugZug_UI_Show()
            end
        end)
    elseif event == "PLAYER_LOGOUT" then
        if ZugZug.LFG and ZugZug.LFG.myListingId then
            ZugZug_LFG_CloseListing(ZugZug.LFG.myListingId)
        end
    elseif event == "CHAT_MSG_ADDON" then
        ZugZug_OnAddonMessage()

    elseif event == "CHAT_MSG_GUILD" then
        local msg = arg1
        local sender = arg2
        if sender and msg then
            ZugZug_AddGuildChatLog(sender, msg)
            if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                ZugZug_UI_ShowTab("dashboard")
            end
        end
    elseif event == "CHAT_MSG_OFFICER" then
        local msg = arg1
        local sender = arg2

        if sender and msg then
            ZugZug_AddOfficerChatLog(sender, msg)

            if ZugZug.UI and ZugZug.UI.activeTab == "officer" then
                ZugZug_UI_ShowTab("officer")
            end
        end
    elseif event == "PARTY_INVITE_REQUEST" then
        if ZugZug_LFG_HandlePartyInvite then
            ZugZug_LFG_HandlePartyInvite(arg1)
        end
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        if ZugZug_LFG_OnPartyChanged then
            ZugZug_LFG_OnPartyChanged()
        end
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
        if ZugZug.UI and ZugZug.UI.activeTab == "guild" then
            ZugZug_UI_ShowTab("guild")
        end
    end
end)
