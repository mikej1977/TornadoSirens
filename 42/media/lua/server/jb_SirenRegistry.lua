-- jb_SirenRegistry.lua

if isClient() then return end

require "TornadoSiren/jb_SirenConfig"

local Config = TornadoSiren.Config
local locKey = TornadoSiren.locKey

TornadoSirenServer = TornadoSirenServer or {}

local serverInitialized = false

-- key = { x, y, z, active, elapsed, phase }
function TornadoSirenServer.GetRegistry()
    local data = ModData.getOrCreate("TornadoSirenRegistry")
    if not data.sirens then data.sirens = {} end
    
    -- when server/game first loads, reset active sirens so they continue play again
    if not serverInitialized then
        for _, e in pairs(data.sirens) do
            if e.active then
                e.elapsed = 0
            end
        end
        serverInitialized = true
    end
    
    return data.sirens
end

local function entry(x, y, z)
    local reg = TornadoSirenServer.GetRegistry()
    local key = locKey(x, y, z)
    if not reg[key] then reg[key] = { x = x, y = y, z = z, active = false, phase = 0.0 } end
    if not reg[key].phase then reg[key].phase = 0.0 end
    return reg[key]
end

local function broadcast(x, y, z, active, cut, phase)
    local args = { x = x, y = y, z = z, active = active, cut = cut, phase = phase }
    if isServer() then
        sendServerCommand("TornadoSiren", "SetActive", args)
    elseif TornadoSirenClient then
        TornadoSirenClient.applyActive(x, y, z, active, cut, phase)
    end
end

TornadoSirenServer.Register = function(_, args)
    entry(args.x, args.y, args.z)
end

TornadoSirenServer.Start = function(_, args)
    local e = entry(args.x, args.y, args.z)
    e.active = true
    e.elapsed = 0
    broadcast(e.x, e.y, e.z, true, false, e.phase)
    addSound(nil, e.x, e.y, e.z, Config.SOUND_RADIUS, Config.SOUND_VOLUME)
end

TornadoSirenServer.Stop = function(_, args)
    local e = entry(args.x, args.y, args.z)
    e.active = false
    e.elapsed = nil
    broadcast(e.x, e.y, e.z, false, args.cut, e.phase)
end

TornadoSirenServer.RequestSync = function(_, _)
    if not isServer() then return end
    for _, e in pairs(TornadoSirenServer.GetRegistry()) do
        if e.active or (e.phase and e.phase > 0) then
            sendServerCommand("TornadoSiren", "SetActive",
                { x = e.x, y = e.y, z = e.z, active = e.active, phase = e.phase })
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
            e.phase = ((e.phase or 0) + dt / Config.SPIN_SECONDS) % 1.0
            if e.elapsed >= Config.RUN_SECONDS then
                TornadoSirenServer.Stop(nil, e)
            end
        end
    end
end

Events.OnTick.Add(OnTick)

local function EveryOneMinute()
    for _, e in pairs(TornadoSirenServer.GetRegistry()) do
        if e.active then
            addSound(nil, e.x, e.y, e.z, Config.SOUND_RADIUS, Config.SOUND_VOLUME)
        end
    end
end

Events.EveryOneMinute.Add(EveryOneMinute)
