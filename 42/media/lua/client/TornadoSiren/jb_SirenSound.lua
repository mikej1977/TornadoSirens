-- jb_SirenSound.lua

require "TornadoSiren/jb_SirenConfig"

local Config = TornadoSiren.Config
local locKey = TornadoSiren.locKey

local Sound = {}
TornadoSiren.Sound = Sound
local emitters = {}
local emitterTicks = {}
local count = 0

function Sound.updatePos(key, x, y, z)
    local emitter = emitters[key]
    if emitter then
        emitter:setPos(x, y, z)
    end
end

function Sound.isPlaying(key)
    local emitter = emitters[key]
    if not emitter then return false end
    if emitterTicks[key] and emitterTicks[key] > 0 then return true end
    return emitter:isPlaying(Config.SOUND_SCRIPT)
end

function Sound.start(obj)
    local sq = obj:getSquare()
    if not sq then return end
    local key = locKey(sq:getX(), sq:getY(), sq:getZ())

    if Sound.isPlaying(key) then return end

    local emitter = emitters[key]
    if not emitter then
        emitter = FMODSoundEmitter.new()
        --emitter = getWorld():getFreeEmitter(sq:getX(), sq:getY(), sq:getZ())
        emitters[key] = emitter
        count = count + 1
    end

    emitterTicks[key] = 30 -- delay to check if the sound isn't playing like it should
    emitter:setPos(sq:getX(), sq:getY(), 2)
    emitter:playSound(Config.SOUND_SCRIPT)
end

function Sound.stop(x, y, z)
    local key = locKey(x, y, z)
    local emitter = emitters[key]
    if emitter then
        emitter:stopSoundByName(Config.SOUND_SCRIPT)
        emitters[key] = nil
        emitterTicks[key] = nil
        count = count - 1
    end
end

function Sound.tickAll()
    if count == 0 then return end
    local done = nil
    for key, emitter in pairs(emitters) do
        emitter:tick()
        
        if emitterTicks[key] and emitterTicks[key] > 0 then
            emitterTicks[key] = emitterTicks[key] - 1
        elseif not emitter:isPlaying(Config.SOUND_SCRIPT) then
            done = done or {}
            table.insert(done, key)
        end
    end
    
    if done then
        for _, key in ipairs(done) do
            if emitters[key] then
                emitters[key] = nil
                emitterTicks[key] = nil
                count = count - 1
            end
        end
    end
end
