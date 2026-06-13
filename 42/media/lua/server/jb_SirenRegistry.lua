-- jb_SirenRegistry.lua

if isClient() then return end

require "TornadoSiren/jb_SirenConfig"

local Config = TornadoSiren.Config
local locKey = TornadoSiren.locKey

TornadoSirenServer = TornadoSirenServer or {}

-- key = { x, y, z, active, elapsed }
function TornadoSirenServer.GetRegistry()
    local data = ModData.getOrCreate("TornadoSirenRegistry")
    if not data.sirens then data.sirens = {} end
    return data.sirens
end

local function entry(x, y, z)
    local reg = TornadoSirenServer.GetRegistry()
    local key = locKey(x, y, z)
    if not reg[key] then reg[key] = { x = x, y = y, z = z, active = false } end
    return reg[key]
end

local function broadcast(x, y, z, active, cut)
    local args = { x = x, y = y, z = z, active = active, cut = cut }
    if isServer() then
        sendServerCommand("TornadoSiren", "SetActive", args)
    elseif TornadoSirenClient then
        TornadoSirenClient.applyActive(x, y, z, active, cut)
    end
end

TornadoSirenServer.Register = function(_, args)
    entry(args.x, args.y, args.z)
end

TornadoSirenServer.Start = function(_, args)
    local e = entry(args.x, args.y, args.z)
    e.active = true
    e.elapsed = 0
    broadcast(e.x, e.y, e.z, true)
    addSound(nil, e.x, e.y, e.z, Config.SOUND_RADIUS, Config.SOUND_VOLUME)
end

TornadoSirenServer.Stop = function(_, args)
    local e = entry(args.x, args.y, args.z)
    e.active = false
    e.elapsed = nil
    broadcast(e.x, e.y, e.z, false, args.cut)
end

TornadoSirenServer.RequestSync = function(_, _)
    if not isServer() then return end
    for _, e in pairs(TornadoSirenServer.GetRegistry()) do
        if e.active then
            sendServerCommand("TornadoSiren", "SetActive",
                { x = e.x, y = e.y, z = e.z, active = true })
        end
    end
end

local function onClientCommand(module, command, playerObj, args)
    if module == "TornadoSiren" and TornadoSirenServer[command] then
        TornadoSirenServer[command](playerObj, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)

local function OnTick()
    local dt = getGameTime():getRealworldSecondsSinceLastUpdate()
    for _, e in pairs(TornadoSirenServer.GetRegistry()) do
        if e.active then
            e.elapsed = (e.elapsed or 0) + dt
            if e.elapsed >= Config.RUN_SECONDS then
                TornadoSirenServer.Stop(nil, e)
            end
        end
    end
end

Events.OnTick.Add(OnTick)

-- re-ding every game minute when a siren is sirening
local function EveryOneMinute()
    for _, e in pairs(TornadoSirenServer.GetRegistry()) do
        if e.active then
            addSound(nil, e.x, e.y, e.z, Config.SOUND_RADIUS, Config.SOUND_VOLUME)
        end
    end
end

Events.EveryOneMinute.Add(EveryOneMinute)
