-- jb_SirenController.lua  (client)

require "TornadoSiren/jb_SirenConfig"
require "TornadoSiren/jb_SirenInstances"
require "TornadoSiren/jb_SirenSound"

local Config = TornadoSiren.Config
local Instances = TornadoSiren.Instances
local Sound = TornadoSiren.Sound
local locKey = TornadoSiren.locKey

TornadoSirenClient = TornadoSirenClient or {}

local activeKeys = {}
local activeCount = 0
local phase = 0.0

local function setActiveKey(key, on)
    if on and not activeKeys[key] then
        activeKeys[key] = true
        activeCount = activeCount + 1
    elseif not on and activeKeys[key] then
        activeKeys[key] = nil
        activeCount = activeCount - 1
    end
end

function TornadoSirenClient.isActive(x, y, z)
    return activeKeys[locKey(x, y, z)] == true
end

function TornadoSirenClient.getSirenObject(square)
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj:hasModData() and obj:getModData().isTornadoSiren then
            return obj
        end
    end
    return nil
end

local function loadedSiren(x, y, z)
    return TornadoSirenClient.getSirenObject(getCell():getGridSquare(x, y, z))
end

function TornadoSirenClient.applyActive(x, y, z, active, cut)
    setActiveKey(locKey(x, y, z), active)
    local obj = loadedSiren(x, y, z)
    if active then
        if obj then Sound.start(obj) end
    else
        if obj then Instances.setFrame(obj, 0.0) end  -- park it
        if cut then Sound.stop(x, y, z) end
    end
end

function TornadoSirenClient.attachSiren(obj)
    Instances.attach(obj)
    local sq = obj:getSquare()
    if sq and activeKeys[locKey(sq:getX(), sq:getY(), sq:getZ())] then
        Sound.start(obj)
    end
end

local function request(command, args)
    if isClient() then
        sendClientCommand("TornadoSiren", command, args)
    elseif TornadoSirenServer and TornadoSirenServer[command] then
        TornadoSirenServer[command](nil, args)
    end
end

function TornadoSirenClient.requestRegister(x, y, z) request("Register", { x = x, y = y, z = z }) end
function TornadoSirenClient.requestStart(x, y, z) request("Start", { x = x, y = y, z = z }) end
function TornadoSirenClient.requestStop(x, y, z) request("Stop", { x = x, y = y, z = z, cut = true }) end

local function OnTick()
    Sound.tickAll()
    if activeCount == 0 then return end

    phase = (phase + getGameTime():getRealworldSecondsSinceLastUpdate() / Config.SPIN_SECONDS) % 1.0
    for key in pairs(activeKeys) do
        local rec = Instances.getByKey(key)
        if rec and rec.obj:getSquare() then
            Instances.setFrame(rec.obj, phase)
        end
    end
end

Events.OnTick.Add(OnTick)

local function OnLoadGridsquare(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj:hasModData() and obj:getModData().isTornadoSiren and not Instances.get(obj) then
            TornadoSirenClient.attachSiren(obj)
        end
    end
end

Events.LoadGridsquare.Add(OnLoadGridsquare)

local function EveryOneMinute()
    Instances.removeStaleSirens()
end

Events.EveryOneMinute.Add(EveryOneMinute)

-- toggle siren
local function OnServerCommand(module, command, args)
    if module ~= "TornadoSiren" or command ~= "SetActive" then return end
    TornadoSirenClient.applyActive(args.x, args.y, args.z, args.active, args.cut)
end

Events.OnServerCommand.Add(OnServerCommand)

local function OnGameStart()
    if isClient() then
        sendClientCommand("TornadoSiren", "RequestSync", {})
    elseif TornadoSirenServer then
        for _, e in pairs(TornadoSirenServer.GetRegistry()) do
            if e.active then TornadoSirenClient.applyActive(e.x, e.y, e.z, true) end
        end
    end
end

Events.OnGameStart.Add(OnGameStart)
