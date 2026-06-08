ZugZug.LFG = {}
ZugZug.LFG.listings = {}
ZugZug.LFG.myListingId = nil
ZugZug.LFG.lastAdvertise = 0
ZugZug.LFG.advertiseInterval = 45

ZugZug.LFG.showCreatePanel = false
ZugZug.LFG.currentCreateType = "Dungeon"
ZugZug.LFG.currentCreateTarget = nil
ZugZug.LFG.currentCustomTarget = ""
ZugZug.LFG.currentCreateNote = ""
ZugZug.LFG.currentCreateRole = "DPS"
ZugZug.LFG.createNeedTank = 1
ZugZug.LFG.createNeedHealer = 1
ZugZug.LFG.createNeedDps = 3
ZugZug.LFG.pendingJoinRequests = {}
ZugZug.LFG.pendingJoinTimeout = 20
ZugZug.LFG.joinRoleListingId = nil
ZugZug.LFG.pendingAutoAcceptLeader = nil
ZugZug.LFG.pendingAutoAcceptListingId = nil
ZugZug.LFG.pendingAutoAcceptExpires = 0

local function ZugZug_LFG_Encode(text)
    local s = text or ""
    s = string.gsub(s, "&", "&#38;")
    s = string.gsub(s, ":", "&#58;")
    s = string.gsub(s, ";", "&#59;")
    s = string.gsub(s, ",", "&#44;")
    s = string.gsub(s, "~", "&#126;")
    s = string.gsub(s, "\r", "")
    s = string.gsub(s, "\n", " ")
    return s
end

local function ZugZug_LFG_Decode(text)
    local s = text or ""
    s = string.gsub(s, "&#126;", "~")
    s = string.gsub(s, "&#44;", ",")
    s = string.gsub(s, "&#59;", ";")
    s = string.gsub(s, "&#58;", ":")
    s = string.gsub(s, "&#38;", "&")
    return s
end

local function ZugZug_LFG_Split(text, delim)
    local result = {}
    local startPos = 1
    local index = 1

    if not text then
        return result
    end

    while true do
        local pos = string.find(text, delim, startPos, true)
        if not pos then
            result[index] = string.sub(text, startPos)
            break
        end

        result[index] = string.sub(text, startPos, pos - 1)
        index = index + 1
        startPos = pos + string.len(delim)
    end

    return result
end

local function ZugZug_LFG_RefreshUIImmediate()
    if ZugZug.UI and ZugZug.UI.activeTab == "lfg" then
        if ZugZug_UI_RefreshActiveTab then
            ZugZug_UI_RefreshActiveTab()
        else
            ZugZug_UI_ShowTab("lfg")
        end
    end
end

local function ZugZug_LFG_RefreshUIThrottled(reason)
    if ZugZug.UI and ZugZug.UI.activeTab == "lfg" then
        if ZugZug_UI_RefreshActiveTabThrottled then
            ZugZug_UI_RefreshActiveTabThrottled(reason or "lfg", 0.25)
        else
            ZugZug_UI_ShowTab("lfg")
        end
    end
end

local function ZugZug_LFG_NewId()
    return UnitName("player") .. tostring(time())
end

local function ZugZug_LFG_GetPlayerClass()
    local _, class = UnitClass("player")
    if class then return class end
    return ""
end

local function ZugZug_LFG_GetPlayerLevel()
    local level = UnitLevel("player")
    if level then return level end
    return 0
end

local function ZugZug_LFG_GetPlayerZone()
    if GetRealZoneText then
        return GetRealZoneText() or ""
    end
    if GetZoneText then
        return GetZoneText() or ""
    end
    return ""
end

function ZugZug_LFG_IsCreateOpen()
    if ZugZug.LFG and ZugZug.LFG.showCreatePanel then
        return true
    end

    return false
end

function ZugZug_LFG_SetCreateOpen(open)
    if open then
        ZugZug.LFG.showCreatePanel = true
    else
        ZugZug.LFG.showCreatePanel = false
    end
end

function ZugZug_LFG_GetCreateNote()
    if ZugZug.LFG and ZugZug.LFG.currentCreateNote then
        return ZugZug.LFG.currentCreateNote
    end

    return ""
end

function ZugZug_LFG_SetCreateNote(note)
    if not note then note = "" end
    ZugZug.LFG.currentCreateNote = note
end

local function ZugZug_LFG_FindMember(listing, name)
    if not listing or not listing.members or not name then return nil end

    local i = 1
    while i <= table.getn(listing.members) do
        local member = listing.members[i]

        if member and member.name == name then
            return member
        end

        i = i + 1
    end

    return nil
end

local function ZugZug_LFG_AddOrUpdateMember(listing, name, role, class, level)
    if not listing or not name or name == "" then return end
    if not listing.members then listing.members = {} end

    if not ZugZug_LFG_IsValidRole(role) then
        role = ZugZug_LFG_GetSavedRoleForMember(name)
    end

    if ZugZug_SaveLFGRole then
        ZugZug_SaveLFGRole(name, role)
    end

    local member = ZugZug_LFG_FindMember(listing, name)

    if member then
        member.role = role or member.role or "DPS"
        member.class = class or member.class or ""
        member.level = level or member.level or 0
        return
    end

    table.insert(listing.members, {
        name = name,
        role = role or "DPS",
        class = class or "",
        level = level or 0,
    })
end

local function ZugZug_LFG_RemoveMember(listing, name)
    if not listing or not listing.members or not name then return end

    local i = 1
    while i <= table.getn(listing.members) do
        local member = listing.members[i]

        if member and member.name == name then
            table.remove(listing.members, i)
            return
        end

        i = i + 1
    end
end

function ZugZug_LFG_IsValidRole(role)
    if role == "TANK" then return true end
    if role == "HEALER" then return true end
    if role == "DPS" then return true end
    return false
end

function ZugZug_LFG_CountRoles(listing)
    local counts = {
        TANK = 0,
        HEALER = 0,
        DPS = 0,
    }

    if not listing or not listing.members then
        return counts
    end

    local i = 1
    while i <= table.getn(listing.members) do
        local member = listing.members[i]
        local role = nil

        if member then
            role = member.role or "DPS"
        end

        if not ZugZug_LFG_IsValidRole(role) then
            role = "DPS"
        end

        if member and member.name then
            counts[role] = (counts[role] or 0) + 1
        end

        i = i + 1
    end

    return counts
end

function ZugZug_LFG_GetNeedForRole(listing, role)
    if not listing then return 0 end
    if role == "TANK" then return tonumber(listing.needTank or 0) or 0 end
    if role == "HEALER" then return tonumber(listing.needHealer or 0) or 0 end
    if role == "DPS" then return tonumber(listing.needDps or 0) or 0 end
    return 0
end

function ZugZug_LFG_GetHaveForRole(listing, role)
    local counts = ZugZug_LFG_CountRoles(listing)
    return tonumber(counts[role] or 0) or 0
end

function ZugZug_LFG_IsRoleFull(listing, role)
    local need = ZugZug_LFG_GetNeedForRole(listing, role)
    if need <= 0 then return true end
    return ZugZug_LFG_GetHaveForRole(listing, role) >= need
end

function ZugZug_LFG_IsListingFull(listing)
    if not listing then return true end
    if not ZugZug_LFG_IsRoleFull(listing, "TANK") then return false end
    if not ZugZug_LFG_IsRoleFull(listing, "HEALER") then return false end
    if not ZugZug_LFG_IsRoleFull(listing, "DPS") then return false end
    return true
end

function ZugZug_LFG_GetCreateRole()
    if ZugZug_LFG_IsValidRole(ZugZug.LFG.currentCreateRole) then
        return ZugZug.LFG.currentCreateRole
    end
    local savedRole = ZugZug_LFG_GetSavedRoleForMember(UnitName("player"))
    ZugZug.LFG.currentCreateRole = savedRole
    return savedRole
end

function ZugZug_LFG_SetCreateRole(role)
    if not ZugZug_LFG_IsValidRole(role) then
        role = "DPS"
    end
    ZugZug.LFG.currentCreateRole = role
    if ZugZug_SaveLFGRole then
        ZugZug_SaveLFGRole(UnitName("player"), role)
    end
end

function ZugZug_LFG_IsInMyPartyOrRaid(name)
    if not name or name == "" then return false end

    local playerName = UnitName("player")

    if name == playerName then
        if GetNumRaidMembers and GetNumRaidMembers() > 0 then
            return true
        end

        if GetNumPartyMembers and GetNumPartyMembers() > 0 then
            return true
        end

        return false
    end

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        local i = 1

        while i <= GetNumRaidMembers() do
            local unit = "raid" .. tostring(i)

            if UnitName(unit) == name then
                return true
            end

            i = i + 1
        end
    end

    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        local i = 1

        while i <= GetNumPartyMembers() do
            local unit = "party" .. tostring(i)

            if UnitName(unit) == name then
                return true
            end

            i = i + 1
        end
    end

    return false
end

function ZugZug_LFG_GetListingMemberRole(listing, name)
    if not listing or not listing.members or not name then return nil end

    local i = 1
    while i <= table.getn(listing.members) do
        local member = listing.members[i]

        if member and member.name == name then
            return member.role
        end

        i = i + 1
    end

    return nil
end

local function ZugZug_LFG_GetUnitClass(unit)
    if not unit then return "" end

    local className = nil
    local englishClass = nil

    if UnitClass then
        className, englishClass = UnitClass(unit)
    end

    if englishClass then return englishClass end
    if className then return className end

    return ""
end

local function ZugZug_LFG_GetUnitLevel(unit)
    if not unit then return 0 end

    local level = UnitLevel(unit)
    if level then return level end

    return 0
end

local function ZugZug_LFG_GetPendingRoleForMember(name)
    if not name then return nil end
    if not ZugZug.LFG.pendingJoinRequests then return nil end

    local request = ZugZug.LFG.pendingJoinRequests[name]
    if request and request.role and ZugZug_LFG_IsValidRole(request.role) then
        return request.role
    end

    return nil
end

function ZugZug_LFG_SyncListingFromActualParty(listing)
    if not listing then return end
    if listing.leader ~= UnitName("player") then
        if not ZugZug_LFG_AssumeListingOwnership or not ZugZug_LFG_AssumeListingOwnership(listing) then
            return
        end
    end

    if not listing.members then listing.members = {} end

    local i = table.getn(listing.members)
    while i >= 1 do
        local member = listing.members[i]

        if member and member.name and member.name ~= listing.leader and not ZugZug_LFG_IsInMyPartyOrRaid(member.name) then
            table.remove(listing.members, i)
        end

        i = i - 1
    end

    ZugZug_LFG_AddOrUpdateMember(
        listing,
        UnitName("player"),
        listing.leaderRole or ZugZug_LFG_GetCreateRole(),
        ZugZug_LFG_GetPlayerClass(),
        ZugZug_LFG_GetPlayerLevel()
    )

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        local r = 1

        while r <= GetNumRaidMembers() do
            local unit = "raid" .. tostring(r)
            local name = UnitName(unit)

            if name then
                local role = ZugZug_LFG_GetListingMemberRole(listing, name)
                if not role then role = ZugZug_LFG_GetPendingRoleForMember(name) end
                if not role then role = ZugZug_LFG_GetSavedRoleForMember(name) end

                ZugZug_LFG_AddOrUpdateMember(
                    listing,
                    name,
                    role,
                    ZugZug_LFG_GetUnitClass(unit),
                    ZugZug_LFG_GetUnitLevel(unit)
                )
            end

            r = r + 1
        end

        return
    end

    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        local p = 1

        while p <= GetNumPartyMembers() do
            local unit = "party" .. tostring(p)
            local name = UnitName(unit)

            if name then
                local role = ZugZug_LFG_GetListingMemberRole(listing, name)
                if not role then role = ZugZug_LFG_GetPendingRoleForMember(name) end
                if not role then role = ZugZug_LFG_GetSavedRoleForMember(name) end

                ZugZug_LFG_AddOrUpdateMember(
                    listing,
                    name,
                    role,
                    ZugZug_LFG_GetUnitClass(unit),
                    ZugZug_LFG_GetUnitLevel(unit)
                )
            end

            p = p + 1
        end
    end
end

function ZugZug_LFG_PruneListingToActualParty(listing)
    ZugZug_LFG_SyncListingFromActualParty(listing)
end

function ZugZug_LFG_GetNextRole(role)
    if role == "TANK" then return "HEALER" end
    if role == "HEALER" then return "DPS" end
    return "TANK"
end

function ZugZug_LFG_IsListingMember(listing, name)
    if not listing or not listing.members or not name then return false end

    local i = 1
    while i <= table.getn(listing.members) do
        local member = listing.members[i]

        if member and member.name == name then
            return true
        end

        i = i + 1
    end

    return false
end

function ZugZug_LFG_GetSavedRoleForMember(name)
    local role = nil

    if ZugZug_GetSavedLFGRole then
        role = ZugZug_GetSavedLFGRole(name)
    end

    if ZugZug_LFG_IsValidRole(role) then
        return role
    end

    return "DPS"
end

function ZugZug_LFG_PlayerHasActiveListing()
    local player = UnitName("player")
    if not player then return false end

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing then
            if listing.leader == player then
                return true
            end

            if ZugZug_LFG_IsListingMember(listing, player) then
                return true
            end
        end
    end

    return false
end

function ZugZug_LFG_GetGroupLeaderName()
    local player = UnitName("player")

    if UnitIsPartyLeader and UnitIsPartyLeader("player") then
        return player
    end

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        local i = 1
        while i <= GetNumRaidMembers() do
            local unit = "raid" .. tostring(i)
            if UnitIsPartyLeader and UnitIsPartyLeader(unit) then
                return UnitName(unit)
            end
            i = i + 1
        end
    end

    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        local i = 1
        while i <= GetNumPartyMembers() do
            local unit = "party" .. tostring(i)
            if UnitIsPartyLeader and UnitIsPartyLeader(unit) then
                return UnitName(unit)
            end
            i = i + 1
        end
    end

    return nil
end

function ZugZug_LFG_IsOnlineAddonListingMember(listing, name)
    if not listing or not name or name == "" then return false end
    if not ZugZug_LFG_IsListingMember(listing, name) then return false end
    if not ZugZug_LFG_IsOnline(name) then return false end
    if name == UnitName("player") then return true end
    if ZugZug_GetAddonVersionForMember and ZugZug_GetAddonVersionForMember(name) then return true end
    return false
end

function ZugZug_LFG_CanGroupLeaderKeepListing(listing, name)
    if not listing or not name or name == "" then return false end
    if not ZugZug_LFG_IsOnline(name) then return false end
    if not ZugZug_LFG_IsListingMember(listing, name) and not ZugZug_LFG_IsInMyPartyOrRaid(name) then return false end
    if name == UnitName("player") then return true end
    if ZugZug_GetAddonVersionForMember and ZugZug_GetAddonVersionForMember(name) then return true end
    return false
end

function ZugZug_LFG_GetPreferredKeeper(listing)
    if not listing or not listing.members then return nil end

    local groupLeader = ZugZug_LFG_GetGroupLeaderName()
    if groupLeader and ZugZug_LFG_CanGroupLeaderKeepListing(listing, groupLeader) then
        return groupLeader
    end

    local chosen = nil
    local i = 1

    while i <= table.getn(listing.members) do
        local member = listing.members[i]
        local name = nil

        if member then
            name = member.name
        end

        if name and ZugZug_LFG_IsOnlineAddonListingMember(listing, name) then
            if not chosen or string.lower(name) < string.lower(chosen) then
                chosen = name
            end
        end

        i = i + 1
    end

    return chosen
end

function ZugZug_LFG_ShouldOwnListing(listing)
    local player = UnitName("player")
    if not player then return false end
    return ZugZug_LFG_GetPreferredKeeper(listing) == player
end

function ZugZug_LFG_AssumeListingOwnership(listing)
    local player = UnitName("player")
    if not listing or not player then return false end
    if not ZugZug_LFG_ShouldOwnListing(listing) then return false end
    if listing.leader == player then return false end

    listing.leader = player
    listing.leaderRole = ZugZug_LFG_GetListingMemberRole(listing, player) or ZugZug_LFG_GetCreateRole()
    listing.leaderClass = ZugZug_LFG_GetPlayerClass()
    listing.leaderLevel = ZugZug_LFG_GetPlayerLevel()
    ZugZug.LFG.myListingId = listing.id
    return true
end

function ZugZug_LFG_HasOnlineAddonKeeper(listing)
    if ZugZug_LFG_GetPreferredKeeper(listing) then return true end
    return false
end

function ZugZug_LFG_MaintainListingOwnership()
    local changed = false

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing and ZugZug_LFG_ShouldOwnListing(listing) then
            if ZugZug_LFG_AssumeListingOwnership(listing) then
                changed = true
            end

            if listing.leader == UnitName("player") then
                ZugZug.LFG.myListingId = id
                ZugZug_LFG_SyncListingFromActualParty(listing)
            end
        end
    end

    if changed then
        ZugZug_LFG_SyncToGuild()
    end
end

function ZugZug_LFG_CanCreateListing()
    if ZugZug_LFG_PlayerHasActiveListing() then
        return false
    end

    return true
end

function ZugZug_LFG_SetLocalMemberRole(listing, name, role)
    if not listing or not name or name == "" then return false end

    if not ZugZug_LFG_IsValidRole(role) then
        role = "DPS"
    end

    local member = ZugZug_LFG_FindMember(listing, name)
    if not member then return false end

    member.role = role
    return true
end

function ZugZug_LFG_SetListingMemberRole(id, name, role)
    if not id or id == "" then return end
    if not name or name == "" then return end

    if not ZugZug_LFG_IsValidRole(role) then
        role = "DPS"
    end

    local listing = ZugZug.LFG.listings[id]
    if not listing then return end

    if listing.leader ~= UnitName("player") then
        if not ZugZug_LFG_AssumeListingOwnership(listing) then return end
    end

    local isLeaderSelf = false
    if name == UnitName("player") and listing.leader == UnitName("player") then
        isLeaderSelf = true
    end

    if not isLeaderSelf and not ZugZug_LFG_IsInMyPartyOrRaid(name) then
        return
    end

    if ZugZug_LFG_SetLocalMemberRole(listing, name, role) then
        if name == UnitName("player") then
            listing.leaderRole = role
            ZugZug.LFG.currentCreateRole = role
        end
        ZugZug_LFG_BroadcastListing(listing)
        ZugZug_LFG_RefreshUIImmediate()
    end
end
function ZugZug_LFG_CycleListingMemberRole(id, name)
    if not id or id == "" then return end
    if not name or name == "" then return end

    local listing = ZugZug.LFG.listings[id]
    if not listing then return end

    local currentRole = ZugZug_LFG_GetListingMemberRole(listing, name)
    local nextRole = ZugZug_LFG_GetNextRole(currentRole)

    ZugZug_LFG_SetListingMemberRole(id, name, nextRole)
end

function ZugZug_LFG_RequestMyRoleChange(id, role)
    if not id or id == "" then return end

    if not ZugZug_LFG_IsValidRole(role) then
        role = "DPS"
    end

    if ZugZug_SaveLFGRole then
        ZugZug_SaveLFGRole(UnitName("player"), role)
    end

    ZugZug.LFG.currentCreateRole = role

    local listing = ZugZug.LFG.listings[id]
    if not listing then return end

    local player = UnitName("player")

    if listing.leader == player then
        ZugZug_LFG_SetListingMemberRole(id, player, role)
        return
    end

    if not ZugZug_LFG_IsListingMember(listing, player) then
        return
    end

    ZugZug_BroadcastAddon("LFG_ROLE_REQUEST~"
        .. ZugZug_LFG_Encode(id) .. ":"
        .. ZugZug_LFG_Encode(role)
    )

    ZugZug_LFG_RefreshUIImmediate()
end

function ZugZug_LFG_IsExpectedInvite(inviter)
    if not inviter or inviter == "" then return false end
    if not ZugZug.LFG.pendingAutoAcceptLeader then return false end

    if time() > (ZugZug.LFG.pendingAutoAcceptExpires or 0) then
        ZugZug.LFG.pendingAutoAcceptLeader = nil
        ZugZug.LFG.pendingAutoAcceptListingId = nil
        ZugZug.LFG.pendingAutoAcceptExpires = 0
        return false
    end

    if inviter == ZugZug.LFG.pendingAutoAcceptLeader then
        return true
    end

    return false
end

function ZugZug_LFG_HandlePartyInvite(inviter)
    if not ZugZug_LFG_IsExpectedInvite(inviter) then
        return false
    end

    AcceptGroup()

    if StaticPopup_Hide then
        StaticPopup_Hide("PARTY_INVITE")
    end

    ZugZug.LFG.pendingAutoAcceptLeader = nil
    ZugZug.LFG.pendingAutoAcceptListingId = nil
    ZugZug.LFG.pendingAutoAcceptExpires = 0

    return true
end

local function ZugZug_LFG_EncodeMembers(members)
    local text = ""
    local i = 1
    while members and i <= table.getn(members) do
        local member = members[i]
        if member and member.name then
            if text ~= "" then
                text = text .. ";"
            end
            text = text
                .. ZugZug_LFG_Encode(member.name) .. ","
                .. ZugZug_LFG_Encode(member.role or "DPS") .. ","
                .. ZugZug_LFG_Encode(member.class or "") .. ","
                .. tostring(member.level or 0)
        end
        i = i + 1
    end
    return text
end

local function ZugZug_LFG_DecodeMembers(text)
    local members = {}
    if not text or text == "" then return members end
    local rows = ZugZug_LFG_Split(text, ";")
    local i = 1
    while i <= table.getn(rows) do
        local row = rows[i]
        local parts = ZugZug_LFG_Split(row, ",")
        if parts[1] and parts[1] ~= "" then
            table.insert(members, {
                name = ZugZug_LFG_Decode(parts[1] or ""),
                role = ZugZug_LFG_Decode(parts[2] or "DPS"),
                class = ZugZug_LFG_Decode(parts[3] or ""),
                level = tonumber(parts[4] or "0") or 0,
            })
        end
        i = i + 1
    end
    return members
end

local function ZugZug_LFG_EncodeListing(listing)
    if not listing then return "" end

    return ZugZug_LFG_Encode(listing.id or "") .. ":"
        .. ZugZug_LFG_Encode(listing.type or "") .. ":"
        .. ZugZug_LFG_Encode(listing.target or "") .. ":"
        .. ZugZug_LFG_Encode(listing.zone or "") .. ":"
        .. ZugZug_LFG_Encode(listing.leader or "") .. ":"
        .. ZugZug_LFG_Encode(listing.leaderClass or "") .. ":"
        .. tostring(listing.leaderLevel or 0) .. ":"
        .. tostring(listing.needTank or 0) .. ":"
        .. tostring(listing.needHealer or 0) .. ":"
        .. tostring(listing.needDps or 0) .. ":"
        .. ZugZug_LFG_Encode(listing.note or "") .. ":"
        .. tostring(listing.createdAt or time()) .. ":"
        .. tostring(listing.expiresAt or (time() + 1800)) .. ":"
        .. ZugZug_LFG_EncodeMembers(listing.members) .. ":"
        .. ZugZug_LFG_Encode(listing.leaderRole or "DPS")
end

local function ZugZug_LFG_DecodeListing(data)
    local parts = ZugZug_LFG_Split(data, ":")

    if not parts[1] or parts[1] == "" then
        return nil
    end

    local leaderRole = ZugZug_LFG_Decode(parts[15] or "DPS")
    if not ZugZug_LFG_IsValidRole(leaderRole) then
        leaderRole = "DPS"
    end

    return {
        id = ZugZug_LFG_Decode(parts[1] or ""),
        type = ZugZug_LFG_Decode(parts[2] or ""),
        target = ZugZug_LFG_Decode(parts[3] or ""),
        zone = ZugZug_LFG_Decode(parts[4] or ""),
        leader = ZugZug_LFG_Decode(parts[5] or ""),
        leaderClass = ZugZug_LFG_Decode(parts[6] or ""),
        leaderLevel = tonumber(parts[7] or "0") or 0,
        needTank = tonumber(parts[8] or "0") or 0,
        needHealer = tonumber(parts[9] or "0") or 0,
        needDps = tonumber(parts[10] or "0") or 0,
        note = ZugZug_LFG_Decode(parts[11] or ""),
        createdAt = tonumber(parts[12] or "0") or time(),
        expiresAt = tonumber(parts[13] or "0") or (time() + 1800),
        members = ZugZug_LFG_DecodeMembers(parts[14] or ""),
        leaderRole = leaderRole,
    }
end

function ZugZug_LFG_GetCreateType()
    if ZugZug.LFG.currentCreateType then
        return ZugZug.LFG.currentCreateType
    end

    return "Dungeon"
end

function ZugZug_LFG_SetCreateType(lfgType)
    if not lfgType or lfgType == "" then
        lfgType = "Dungeon"
    end

    ZugZug.LFG.currentCreateType = lfgType

    if lfgType == "Other" then
        ZugZug.LFG.currentCreateTarget = ""
    else
        ZugZug.LFG.currentCreateTarget = ZugZug_LFG_GetFirstTargetForType(lfgType)
    end
end

function ZugZug_LFG_GetCreateTarget()
    local lfgType = ZugZug_LFG_GetCreateType()

    if lfgType == "Other" then
        return ZugZug.LFG.currentCustomTarget or ""
    end

    if not ZugZug.LFG.currentCreateTarget or ZugZug.LFG.currentCreateTarget == "" then
        ZugZug.LFG.currentCreateTarget = ZugZug_LFG_GetFirstTargetForType(lfgType)
    end

    return ZugZug.LFG.currentCreateTarget or ""
end

function ZugZug_LFG_SetCreateTarget(target)
    local lfgType = ZugZug_LFG_GetCreateType()

    if not target then target = "" end

    if lfgType == "Other" then
        ZugZug.LFG.currentCustomTarget = target
    else
        ZugZug.LFG.currentCreateTarget = target
    end
end

function ZugZug_LFG_AdjustNeed(role, amount)
    if role == "TANK" then
        ZugZug.LFG.createNeedTank = ZugZug.LFG.createNeedTank + amount
        if ZugZug.LFG.createNeedTank < 0 then ZugZug.LFG.createNeedTank = 0 end
        if ZugZug.LFG.createNeedTank > 5 then ZugZug.LFG.createNeedTank = 5 end
    elseif role == "HEALER" then
        ZugZug.LFG.createNeedHealer = ZugZug.LFG.createNeedHealer + amount
        if ZugZug.LFG.createNeedHealer < 0 then ZugZug.LFG.createNeedHealer = 0 end
        if ZugZug.LFG.createNeedHealer > 5 then ZugZug.LFG.createNeedHealer = 5 end
    elseif role == "DPS" then
        ZugZug.LFG.createNeedDps = ZugZug.LFG.createNeedDps + amount
        if ZugZug.LFG.createNeedDps < 0 then ZugZug.LFG.createNeedDps = 0 end
        if ZugZug.LFG.createNeedDps > 20 then ZugZug.LFG.createNeedDps = 20 end
    end
end

function ZugZug_LFG_BroadcastListing(listing)
    if not listing then return end
    ZugZug_BroadcastAddon("LFG_UPSERT~" .. ZugZug_LFG_EncodeListing(listing))
end

function ZugZug_LFG_RequestSync()
    local player = UnitName("player")
    if not player or player == "" then return end
    ZugZug_BroadcastAddon("LFG_SYNC_REQ~" .. ZugZug_LFG_Encode(player))
end

function ZugZug_LFG_SendSyncResponse(target, listing)
    if not target or target == "" then return end
    if not listing then return end

    ZugZug_BroadcastAddon("LFG_SYNC_RES~"
        .. ZugZug_LFG_Encode(target) .. ":"
        .. ZugZug_LFG_EncodeListing(listing)
    )
end

function ZugZug_LFG_RespondToSyncRequest(target)
    if not target or target == "" then return end

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing then
            if ZugZug_LFG_IsListingMember(listing, target) then
                ZugZug_LFG_SendSyncResponse(target, listing)
            elseif ZugZug_LFG_ShouldOwnListing(listing) then
                ZugZug_LFG_SendSyncResponse(target, listing)
            end
        end
    end
end

function ZugZug_LFG_CreateListing(target, note)
    if ZugZug_LFG_CanCreateListing and not ZugZug_LFG_CanCreateListing() then
        ZugZug_Log("You are already in a guild LFG.")
        return
    end

    target = target or ZugZug_LFG_GetCreateTarget()
    target = ZugZug_NormalizeString(target)
    note = note or ""

    if not target then
        ZugZug_Log("LFG target is required.")
        return
    end

    local player = UnitName("player")
    local now = time()
    local leaderRole = ZugZug_LFG_GetCreateRole()

    if ZugZug_SaveLFGRole then
        ZugZug_SaveLFGRole(player, leaderRole)
    end

    local listing = {
        id = ZugZug_LFG_NewId(),
        type = ZugZug_LFG_GetCreateType(),
        target = target,
        zone = ZugZug_LFG_GetPlayerZone(),
        leader = player,
        leaderRole = leaderRole,
        leaderClass = ZugZug_LFG_GetPlayerClass(),
        leaderLevel = ZugZug_LFG_GetPlayerLevel(),
        needTank = ZugZug.LFG.createNeedTank or 0,
        needHealer = ZugZug.LFG.createNeedHealer or 0,
        needDps = ZugZug.LFG.createNeedDps or 0,
        note = note,
        createdAt = now,
        expiresAt = now + 1800,
        members = {},
    }

    ZugZug.LFG.listings[listing.id] = listing
    ZugZug.LFG.myListingId = listing.id

    ZugZug_LFG_SyncListingFromActualParty(listing)

    ZugZug_LFG_BroadcastListing(listing)
    ZugZug_Log("LFG posted: " .. listing.target)

    ZugZug.LFG.showCreatePanel = false
    ZugZug.LFG.currentCreateNote = ""

    ZugZug_LFG_RefreshUIImmediate()
end

function ZugZug_LFG_CloseListing(id)
    if not id or id == "" then return end

    local listing = ZugZug.LFG.listings[id]
    if listing and listing.leader ~= UnitName("player") and not ZugZug_LFG_ShouldOwnListing(listing) then
        return
    end

    ZugZug.LFG.listings[id] = nil

    if ZugZug.LFG.myListingId == id then
        ZugZug.LFG.myListingId = nil
    end

    ZugZug_BroadcastAddon("LFG_CLOSE~" .. ZugZug_LFG_Encode(id))

    ZugZug_LFG_RefreshUIImmediate()
end

function ZugZug_LFG_JoinListing(id, role)
    if not id or id == "" then return end

    if not ZugZug_LFG_IsValidRole(role) then
        role = "DPS"
    end

    local listing = ZugZug.LFG.listings[id]
    if not listing then return end

    if ZugZug_LFG_IsListingFull(listing) then
        ZugZug_Log("That LFG is already full.")
        ZugZug.UI.selectedJoinListingId = nil
        ZugZug_LFG_RefreshUIImmediate()
        return
    end

    if ZugZug_LFG_IsRoleFull(listing, role) then
        ZugZug_Log("That LFG already has enough " .. role .. ".")
        ZugZug.UI.selectedJoinListingId = nil
        ZugZug_LFG_RefreshUIImmediate()
        return
    end

    if listing.leader == UnitName("player") then
        return
    end

    if ZugZug_LFG_PlayerHasActiveListing and ZugZug_LFG_PlayerHasActiveListing() then
        ZugZug_Log("You are already in a guild LFG.")
        ZugZug.UI.selectedJoinListingId = nil

        ZugZug_LFG_RefreshUIImmediate()

        return
    end

    if ZugZug_SaveLFGRole then
        ZugZug_SaveLFGRole(UnitName("player"), role)
    end

    ZugZug.LFG.currentCreateRole = role
    ZugZug.LFG.pendingAutoAcceptLeader = listing.leader
    ZugZug.LFG.pendingAutoAcceptListingId = id
    ZugZug.LFG.pendingAutoAcceptExpires = time() + 20

    ZugZug_BroadcastAddon("LFG_JOIN_REQUEST~"
        .. ZugZug_LFG_Encode(id) .. ":"
        .. ZugZug_LFG_Encode(role) .. ":"
        .. ZugZug_LFG_Encode(ZugZug_LFG_GetPlayerClass()) .. ":"
        .. tostring(ZugZug_LFG_GetPlayerLevel())
    )

    ZugZug.UI.selectedJoinListingId = nil
    ZugZug_Log("Join request sent to " .. listing.leader .. ".")

    ZugZug_LFG_RefreshUIImmediate()
end

function ZugZug_LFG_LeaveListing(id)
    if not id or id == "" then return end

    local listing = ZugZug.LFG.listings[id]
    if not listing then return end

    local player = UnitName("player")
    ZugZug_LFG_RemoveMember(listing, player)

    ZugZug_BroadcastAddon("LFG_LEAVE~" .. ZugZug_LFG_Encode(id))

    ZugZug_LFG_RefreshUIImmediate()
end

function ZugZug_LFG_HandleMessage(cmd, data, sender)
    if cmd == "LFG_SYNC_REQ" then
        local target = ZugZug_LFG_Decode(data or "")

        if target and target ~= "" and target ~= UnitName("player") then
            ZugZug_LFG_RespondToSyncRequest(target)
        end

        return
    end

    if cmd == "LFG_SYNC_RES" then
        local sep = string.find(data or "", ":", 1, true)
        if not sep then return end

        local target = ZugZug_LFG_Decode(string.sub(data, 1, sep - 1))
        if not target or target == "" then return end
        if string.lower(target) ~= string.lower(UnitName("player") or "") then return end

        local listing = ZugZug_LFG_DecodeListing(string.sub(data, sep + 1))
        if not listing then return end

        if listing.expiresAt and listing.expiresAt < time() then
            return
        end

        ZugZug.LFG.listings[listing.id] = listing

        if ZugZug_LFG_IsListingMember(listing, UnitName("player")) then
            ZugZug.LFG.myListingId = listing.id
        end

        if ZugZug_LFG_MaintainListingOwnership then
            ZugZug_LFG_MaintainListingOwnership()
        end

        ZugZug_LFG_RefreshUIThrottled("lfg_sync_res")
        return
    end

    if cmd == "LFG_UPSERT" then
        local listing = ZugZug_LFG_DecodeListing(data)
        if not listing then return end
        local isNewListing = false

        if listing.id and not ZugZug.LFG.listings[listing.id] then
            isNewListing = true
        end

        if listing.expiresAt and listing.expiresAt < time() then
            ZugZug.LFG.listings[listing.id] = nil
            return
        end

        ZugZug.LFG.listings[listing.id] = listing

        if isNewListing
            and listing.leader ~= UnitName("player")
            and sender ~= UnitName("player")
            and ZugZug_GetEnableLFGNotifications
            and ZugZug_GetEnableLFGNotifications()
        then
            ZugZug_Log("New LFG: " .. (listing.target or "?") .. " by " .. (listing.leader or "?"))
        end

        ZugZug_LFG_RefreshUIThrottled("lfg_upsert")

        return
    end

    if cmd == "LFG_CLOSE" then
        local id = ZugZug_LFG_Decode(data or "")
        if id and id ~= "" then
            ZugZug.LFG.listings[id] = nil
            if ZugZug.LFG.myListingId == id then
                ZugZug.LFG.myListingId = nil
            end
        end

        ZugZug_LFG_RefreshUIThrottled("lfg_close")

        return
    end

    if cmd == "LFG_JOIN_REQUEST" then
        local parts = ZugZug_LFG_Split(data, ":")
        local id = ZugZug_LFG_Decode(parts[1] or "")
        local role = ZugZug_LFG_Decode(parts[2] or "DPS")
        local class = ZugZug_LFG_Decode(parts[3] or "")
        local level = tonumber(parts[4] or "0") or 0

        if not ZugZug_LFG_IsValidRole(role) then
            role = "DPS"
        end

        if ZugZug_SaveLFGRole then
            ZugZug_SaveLFGRole(sender, role)
        end

        local listing = ZugZug.LFG.listings[id]
        if not listing then return end

        -- Only the current listing keeper invites and later confirms the member.
        if sender and sender ~= UnitName("player") and ZugZug_LFG_ShouldOwnListing(listing) then
            if listing.leader ~= UnitName("player") then
                ZugZug_LFG_AssumeListingOwnership(listing)
            end

            if ZugZug_LFG_IsListingFull(listing) or ZugZug_LFG_IsRoleFull(listing, role) then
                return
            end

            if not ZugZug.LFG.pendingJoinRequests then
                ZugZug.LFG.pendingJoinRequests = {}
            end

            ZugZug.LFG.pendingJoinRequests[sender] = {
                id = id,
                role = role,
                class = class,
                level = level,
                createdAt = time(),
            }

            InviteByName(sender)
        end

        return
    end

    if cmd == "LFG_ROLE_REQUEST" then
        local parts = ZugZug_LFG_Split(data, ":")
        local id = ZugZug_LFG_Decode(parts[1] or "")
        local role = ZugZug_LFG_Decode(parts[2] or "DPS")

        if not ZugZug_LFG_IsValidRole(role) then
            role = "DPS"
        end

        local listing = ZugZug.LFG.listings[id]
        if not listing then return end

        -- Only the current keeper accepts role changes, and only for actual party/raid members.
        if sender and ZugZug_LFG_IsInMyPartyOrRaid(sender) and ZugZug_LFG_ShouldOwnListing(listing) then
            if listing.leader ~= UnitName("player") then
                ZugZug_LFG_AssumeListingOwnership(listing)
            end

            if ZugZug_LFG_SetLocalMemberRole(listing, sender, role) then
                ZugZug_LFG_BroadcastListing(listing)

                ZugZug_LFG_RefreshUIThrottled("lfg_role_request")
            end
        end

        return
    end

    if cmd == "LFG_LEAVE" then
        local id = ZugZug_LFG_Decode(data or "")
        local listing = ZugZug.LFG.listings[id]

        if listing then
            ZugZug_LFG_RemoveMember(listing, sender)

            if ZugZug_LFG_ShouldOwnListing(listing) then
                if listing.leader ~= UnitName("player") then
                    ZugZug_LFG_AssumeListingOwnership(listing)
                end
                ZugZug_LFG_BroadcastListing(listing)
            end
        end

        ZugZug_LFG_RefreshUIThrottled("lfg_leave")

        return
    end
end

function ZugZug_LFG_SyncToGuild()
    local player = UnitName("player")
    if not player then return end

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing and ZugZug_LFG_ShouldOwnListing(listing) then
            if listing.leader ~= player then
                ZugZug_LFG_AssumeListingOwnership(listing)
            end

            if listing.leader == player then
                ZugZug.LFG.myListingId = id
                ZugZug_LFG_SyncListingFromActualParty(listing)
                ZugZug_LFG_BroadcastListing(listing)
            end
        end
    end
end

function ZugZug_LFG_PruneExpired()
    local now = time()

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing and listing.expiresAt and listing.expiresAt < now then
            ZugZug.LFG.listings[id] = nil
            if ZugZug.LFG.myListingId == id then
                ZugZug.LFG.myListingId = nil
            end
        end
    end
end

function ZugZug_LFG_PruneOffline()
    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing and listing.leader then
            local hasKeeper = ZugZug_LFG_HasOnlineAddonKeeper(listing)

            if (not ZugZug_isGuildMember(listing.leader) or not ZugZug_LFG_IsOnline(listing.leader)) and not hasKeeper then
                ZugZug.LFG.listings[id] = nil
            else
                if hasKeeper and ZugZug_LFG_ShouldOwnListing(listing) then
                    ZugZug_LFG_AssumeListingOwnership(listing)
                end

                local i = table.getn(listing.members)
                while i >= 1 do
                    local member = listing.members[i]
                    if member and member.name and not ZugZug_LFG_IsOnline(member.name) and member.name ~= listing.leader then
                        table.remove(listing.members, i)
                    end
                    i = i - 1
                end
            end
        end
    end
end

function ZugZug_LFG_IsOnline(name)
    if not name then return false end

    local i = 1
    while ZugZug.onlineMembers and i <= table.getn(ZugZug.onlineMembers) do
        local member = ZugZug.onlineMembers[i]
        if member and member.name == name then
            return true
        end
        i = i + 1
    end

    return false
end

function ZugZug_LFG_CheckPendingJoins()
    if not ZugZug.LFG.pendingJoinRequests then return end

    local changed = false
    local now = time()

    for name, request in pairs(ZugZug.LFG.pendingJoinRequests) do
        if request and request.id then
            local listing = ZugZug.LFG.listings[request.id]

            if not listing or listing.leader ~= UnitName("player") then
                ZugZug.LFG.pendingJoinRequests[name] = nil
            elseif now - (request.createdAt or now) > (ZugZug.LFG.pendingJoinTimeout or 20) then
                ZugZug.LFG.pendingJoinRequests[name] = nil
            elseif ZugZug_LFG_IsInMyPartyOrRaid(name) then
                if not ZugZug_LFG_IsRoleFull(listing, request.role or "DPS") then
                    ZugZug_LFG_AddOrUpdateMember(
                        listing,
                        name,
                        request.role or "DPS",
                        request.class or "",
                        request.level or 0
                    )

                    changed = true
                end

                ZugZug.LFG.pendingJoinRequests[name] = nil
            end
        else
            ZugZug.LFG.pendingJoinRequests[name] = nil
        end
    end

    if changed and ZugZug.LFG.myListingId then
        local listing = ZugZug.LFG.listings[ZugZug.LFG.myListingId]

        if listing then
            ZugZug_LFG_SyncListingFromActualParty(listing)
            ZugZug_LFG_BroadcastListing(listing)
        end
    end

    if changed then
        ZugZug_LFG_RefreshUIThrottled("lfg_pending_joins")
    end
end

function ZugZug_LFG_OnPartyChanged()
    if ZugZug_LFG_MaintainListingOwnership then
        ZugZug_LFG_MaintainListingOwnership()
    end

    if ZugZug.LFG and ZugZug.LFG.myListingId then
        local listing = ZugZug.LFG.listings[ZugZug.LFG.myListingId]

        if listing and ZugZug_LFG_ShouldOwnListing(listing) then
            if listing.leader ~= UnitName("player") then
                ZugZug_LFG_AssumeListingOwnership(listing)
            end
            ZugZug_LFG_CheckPendingJoins()
            ZugZug_LFG_SyncListingFromActualParty(listing)
            ZugZug_LFG_BroadcastListing(listing)
        end
    end

    ZugZug_LFG_RefreshUIThrottled("lfg_party_changed")
end

function ZugZug_LFG_OnUpdate()
    ZugZug_LFG_PruneExpired()
    if ZugZug_LFG_MaintainListingOwnership then
        ZugZug_LFG_MaintainListingOwnership()
    end
    ZugZug_LFG_CheckPendingJoins()

    if ZugZug.LFG.pendingAutoAcceptLeader and time() > (ZugZug.LFG.pendingAutoAcceptExpires or 0) then
        ZugZug.LFG.pendingAutoAcceptLeader = nil
        ZugZug.LFG.pendingAutoAcceptListingId = nil
        ZugZug.LFG.pendingAutoAcceptExpires = 0
    end

    local now = time()
    if now - (ZugZug.LFG.lastAdvertise or 0) >= ZugZug.LFG.advertiseInterval then
        ZugZug.LFG.lastAdvertise = now
        ZugZug_LFG_SyncToGuild()
    end
end

function ZugZug_LFG_StartTicker()
    if ZugZug.LFG.ticker then return end

    local frame = CreateFrame("Frame")
    frame.elapsed = 0

    frame:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed < 3 then return end
        this.elapsed = 0

        ZugZug_LFG_OnUpdate()
    end)

    ZugZug.LFG.ticker = frame
end

function ZugZug_LFG_GetListingCount()
    local count = 0

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing then
            count = count + 1
        end
    end

    return count
end
