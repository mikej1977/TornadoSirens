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
local sirensState = {}
local activeCount = 0

local function updateSirenState(key, active, phase)
    if not sirensState[key] then sirensState[key] = { phase = 0.0 } end
    if phase then sirensState[key].phase = phase end

    if active and not activeKeys[key] then
        activeKeys[key] = true
        activeCount = activeCount + 1
    elseif not active and activeKeys[key] then
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

function TornadoSirenClient.applyActive(x, y, z, active, cut, phase)
    local key = locKey(x, y, z)
    updateSirenState(key, active, phase)
    local obj = loadedSiren(x, y, z)
    
    if active then
        if obj then Sound.start(obj) end
    else
        if obj then Instances.setFrame(obj, sirensState[key].phase) end
        if cut then Sound.stop(x, y, z) end
    end
end

function TornadoSirenClient.attachSiren(obj)
    Instances.attach(obj)
    local sq = obj:getSquare()
    if not sq then return end
    local key = locKey(sq:getX(), sq:getY(), sq:getZ())
    
    if sirensState[key] and sirensState[key].phase then
        Instances.setFrame(obj, sirensState[key].phase)
    end

    if activeKeys[key] then
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

    local dt = getGameTime():getRealworldSecondsSinceLastUpdate()
    local phaseStep = dt / Config.SPIN_SECONDS

    for key in pairs(activeKeys) do
        local state = sirensState[key]
        if state then
            state.phase = (state.phase + phaseStep) % 1.0
            local rec = Instances.getByKey(key)
            if rec and rec.obj:getSquare() then
                Instances.setFrame(rec.obj, state.phase)
                
                -- no sound? restart it!
                if not Sound.isPlaying(key) then
                    Sound.start(rec.obj)
                else
                    -- put the sound in front of the siren
                    local sq = rec.obj:getSquare()
                    
                    -- convert phase to radians
                    local angle = state.phase * (math.pi * 2)
                    
                    -- how far in front?
                    local radius = 1.0 
                    
                    -- put the shit here
                    local newSoundX = sq:getX() + 0.5 + (math.cos(angle) * radius)
                    local newSoundY = sq:getY() + 0.5 + (math.sin(angle) * radius)
                    local newSoundZ = 2
                    
                    Sound.updatePos(key, newSoundX, newSoundY, newSoundZ)
                end
            end
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

local function OnServerCommand(module, command, args)
    if module ~= "TornadoSiren" or command ~= "SetActive" then return end
    TornadoSirenClient.applyActive(args.x, args.y, args.z, args.active, args.cut, args.phase)
end

Events.OnServerCommand.Add(OnServerCommand)

local function OnGameStart()
    if isClient() then
        sendClientCommand("TornadoSiren", "RequestSync", {})
    elseif TornadoSirenServer then
        for _, e in pairs(TornadoSirenServer.GetRegistry()) do
            TornadoSirenClient.applyActive(e.x, e.y, e.z, e.active, false, e.phase)
        end
    end
end

Events.OnGameStart.Add(OnGameStart)
