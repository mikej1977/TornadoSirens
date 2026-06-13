-- jb_SirenSound.lua

require "TornadoSiren/jb_SirenConfig"

local Config = TornadoSiren.Config
local locKey = TornadoSiren.locKey

local Sound = {}
TornadoSiren.Sound = Sound
local emitters = {}
local count = 0

function Sound.start(obj)
    local sq = obj:getSquare()
    if not sq then return end
    local key = locKey(sq:getX(), sq:getY(), sq:getZ())
    local emitter = emitters[key]
    if emitter and emitter:isPlaying(Config.SOUND_SCRIPT) then return end
    if not emitter then
        emitter = FMODSoundEmitter.new()
        emitters[key] = emitter
        count = count + 1
    end
    emitter:setPos(sq:getX(), sq:getY(), 0)
    emitter:playSound(Config.SOUND_SCRIPT)
end

function Sound.stop(x, y, z)
    local emitter = emitters[locKey(x, y, z)]
    if emitter then emitter:stopSoundByName(Config.SOUND_SCRIPT) end
end

function Sound.tickAll()
    if count == 0 then return end
    local done = nil
    for key, emitter in pairs(emitters) do
        emitter:tick()
        if not emitter:isPlaying(Config.SOUND_SCRIPT) then
            done = done or {}
            table.insert(done, key)
        end
    end
    if done then
        for _, key in ipairs(done) do
            emitters[key] = nil
            count = count - 1
        end
    end
end
