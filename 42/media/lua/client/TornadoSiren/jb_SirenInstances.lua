-- jb_SirenInstances.lua

require "TornadoSiren/jb_SirenConfig"

local Config = TornadoSiren.Config
local locKey = TornadoSiren.locKey

local Instances = {}
TornadoSiren.Instances = Instances

-- key = { sm = SpriteModel, name = string, obj = IsoObject, lastFrame = float }
local sirens = {}

local function keyForObj(obj)
    local sq = obj:getSquare()
    if not sq then return nil end
    return locKey(sq:getX(), sq:getY(), sq:getZ())
end
Instances.keyForObj = keyForObj

function Instances.getByKey(key)
    return sirens[key]
end

function Instances.get(obj)
    local key = keyForObj(obj)
    local rec = key and sirens[key]
    if rec and rec.obj == obj then return rec end
    return nil
end

function Instances.attach(obj)
    local key = keyForObj(obj)
    if not key then return nil end

    local rec = sirens[key]
    if rec then
        rec.obj = obj  -- newest object wins!
    else
        local name = Config.INSTANCE_PREFIX .. key
        local mgr = getScriptManager()
        local sm = mgr:getSpriteModel(name)
        if not sm then
            sm = SpriteModel.new()
            local template = mgr:getSpriteModel(Config.SPINNY_TILE)
            if template then sm:set(template) end
            sm:setModule(mgr:getModule("Base"))
            sm:InitLoadPP(name)
            sm:setModelScriptName(Config.MODEL_SCRIPT)
            sm:setAnimationName(Config.ANIMATION_NAME)
            mgr:addSpriteModel(sm)
        end
        rec = { sm = sm, name = name, obj = obj, lastFrame = -1 }
        sirens[key] = rec
    end

    obj:setSpriteModelName(rec.name)
    Instances.setFrame(obj, 0.0)
    return rec
end

function Instances.setFrame(obj, t)
    local key = keyForObj(obj)
    local rec = key and sirens[key]
    if not rec then return end
    local frame = math.floor(t * Config.SPIN_STEPS) / Config.SPIN_STEPS
    if frame ~= rec.lastFrame then
        rec.lastFrame = frame
        rec.sm:setAnimationTime(frame)
        rec.obj:invalidateRenderChunkLevel(Config.CHUNK_DIRTY_FLAG)
    end
end

function Instances.removeStaleSirens()
    local stale = nil
    for key, rec in pairs(sirens) do
        if rec.obj:getSquare() == nil then
            stale = stale or {}
            table.insert(stale, key)
        end
    end
    if stale then
        for _, key in ipairs(stale) do sirens[key] = nil end
    end
end
