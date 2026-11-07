-- AutoFart: automatically /fart when another player walks past you
local ADDON = ...

local DEFAULTS = {
    enabled = true,
    range = 3,          -- CheckInteractDistance index: 3 = ~10 yd (duel), 2 = ~11 yd (trade), 4 = ~28 yd (follow)
    perPlayerCD = 30,   -- minimum seconds between farts at the same player
    globalCD = 2,       -- minimum seconds between any two farts (spam/throttle guard)
    showFriendlyPlates = true, -- friendly players are only detected when their nameplates are shown
    targetEmote = true, -- aim the emote at the passing player
    noCity = true,      -- stay quiet in rest areas (cities/inns)
    crowdLimit = 8,     -- stay quiet when this many players or more are visible (0 = off)
    maxPerMin = 4,      -- at most this many farts per minute (0 = unlimited)
}

local db
local nearby = {}      -- guid -> true (currently in range)
local lastFartAt = {}  -- guid -> GetTime()
local lastAnyFart = 0
local SCAN_INTERVAL = 0.2

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8fd14fAutoFart|r: " .. msg)
end

local function OnOff(v) return v and "on" or "off" end

local function InRange(unit)
    local ok, res = pcall(CheckInteractDistance, unit, db.range)
    return ok and res
end

local function Fart(unit, guid, now)
    local name = UnitName(unit)
    if db.targetEmote and name then
        DoEmote("FART", name)
    else
        DoEmote("FART")
    end
    lastFartAt[guid] = now
    lastAnyFart = now
end

local recentFarts = {} -- timestamps of farts in the last 60 seconds

local function FartsLastMinute(now)
    local n = 0
    for i = #recentFarts, 1, -1 do
        if now - recentFarts[i] > 60 then table.remove(recentFarts, i) else n = n + 1 end
    end
    return n
end

local function Collect(unit, players)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
    local guid = UnitGUID(unit)
    if not guid or players[guid] then return end
    players[guid] = unit
end

-- Spam guards: returns true if no fart should happen this scan
local function Blocked(now, playerCount, closeCount)
    if UnitIsDeadOrGhost("player") then return true end
    if db.noCity and IsResting() then return true end           -- city / inn
    if db.crowdLimit > 0 and playerCount >= db.crowdLimit then return true end
    if db.crowdLimit > 0 and closeCount >= 3 then return true end -- 3+ people right next to you = crowd
    if db.maxPerMin > 0 and FartsLastMinute(now) >= db.maxPerMin then return true end
    if now - lastAnyFart < db.globalCD then return true end
    return false
end

local function Scan()
    if not db.enabled then return end
    local now = GetTime()

    local players = {}
    for i = 1, 40 do Collect("nameplate" .. i, players) end
    Collect("mouseover", players)
    Collect("target", players)
    for i = 1, 4 do Collect("party" .. i, players) end

    local playerCount, closeCount = 0, 0
    local inRange = {}
    for guid, unit in pairs(players) do
        playerCount = playerCount + 1
        if InRange(unit) then
            inRange[guid] = unit
            closeCount = closeCount + 1
        end
    end

    if not Blocked(now, playerCount, closeCount) then
        -- Only trigger on players who just ENTERED range (the walk-by moment)
        for guid, unit in pairs(inRange) do
            if not nearby[guid] and now - (lastFartAt[guid] or -math.huge) >= db.perPlayerCD then
                Fart(unit, guid, now)
                table.insert(recentFarts, now)
                break -- at most one fart per scan
            end
        end
    end

    -- Players who entered range while blocked count as "already nearby", so
    -- lifting the block doesn't unleash a burst; only newcomers trigger.
    wipe(nearby)
    for guid in pairs(inRange) do nearby[guid] = true end
end

local function ApplyPlateSetting()
    if db.showFriendlyPlates then
        SetCVar("nameplateShowFriends", "1")
    end
end

local f = CreateFrame("Frame")
local elapsed = 0
f:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < SCAN_INTERVAL then return end
    elapsed = 0
    Scan()
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        AutoFartDB = AutoFartDB or {}
        for k, v in pairs(DEFAULTS) do
            if AutoFartDB[k] == nil then AutoFartDB[k] = v end
        end
        db = AutoFartDB
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not InCombatLockdown() then ApplyPlateSetting() end
        wipe(nearby)
        Print(db.enabled and "enabled. Type /af help for options." or "disabled. Type /af on to enable.")
    end
end)

local RANGE_NAMES = { [2] = "~11 yd", [3] = "~10 yd", [4] = "~28 yd" }

SLASH_AUTOFART1 = "/autofart"
SLASH_AUTOFART2 = "/af"
SlashCmdList.AUTOFART = function(msg)
    local cmd, val = strsplit(" ", strtrim(msg or ""):lower(), 2)
    local n = tonumber(val)
    if cmd == "on" then
        db.enabled = true; Print("enabled")
    elseif cmd == "off" then
        db.enabled = false; Print("disabled")
    elseif cmd == "" or cmd == "toggle" then
        db.enabled = not db.enabled; Print(db.enabled and "enabled" or "disabled")
    elseif cmd == "cd" and n then
        db.perPlayerCD = math.max(0, n); Print("per-player cooldown: " .. db.perPlayerCD .. " sec")
    elseif cmd == "gcd" and n then
        db.globalCD = math.max(0, n); Print("global cooldown: " .. db.globalCD .. " sec")
    elseif cmd == "range" and RANGE_NAMES[n] then
        db.range = n; Print("range: " .. RANGE_NAMES[n])
    elseif cmd == "target" then
        db.targetEmote = not db.targetEmote; Print("targeted emote: " .. OnOff(db.targetEmote))
    elseif cmd == "plates" then
        db.showFriendlyPlates = not db.showFriendlyPlates
        SetCVar("nameplateShowFriends", db.showFriendlyPlates and "1" or "0")
        Print("friendly nameplates: " .. OnOff(db.showFriendlyPlates))
    elseif cmd == "city" then
        db.noCity = not db.noCity
        Print("in cities/inns: " .. (db.noCity and "disabled" or "enabled"))
    elseif cmd == "crowd" and n then
        db.crowdLimit = math.max(0, math.floor(n))
        Print("crowd limit: " .. (db.crowdLimit > 0 and (db.crowdLimit .. " players") or "off"))
    elseif cmd == "max" and n then
        db.maxPerMin = math.max(0, math.floor(n))
        Print("max per minute: " .. (db.maxPerMin > 0 and db.maxPerMin or "unlimited"))
    elseif cmd == "test" then
        DoEmote("FART")
    else
        Print("/af  toggle | /af on | /af off | /af test")
        Print("/af cd <sec>  per-player cooldown (now " .. db.perPlayerCD .. ")")
        Print("/af gcd <sec>  global cooldown (now " .. db.globalCD .. ")")
        Print("/af range 2|3|4  trigger range (now " .. RANGE_NAMES[db.range] .. ")")
        Print("/af target  aim the emote at the passing player (now " .. OnOff(db.targetEmote) .. ")")
        Print("/af plates  toggle friendly nameplates (now " .. OnOff(db.showFriendlyPlates) .. ")")
        Print("/af city  work in cities/inns (now " .. (db.noCity and "off" or "on") .. ")")
        Print("/af crowd <n>  pause when n+ players are visible, 0 = off (now " .. db.crowdLimit .. ")")
        Print("/af max <n>  max farts per minute, 0 = unlimited (now " .. db.maxPerMin .. ")")
    end
end
