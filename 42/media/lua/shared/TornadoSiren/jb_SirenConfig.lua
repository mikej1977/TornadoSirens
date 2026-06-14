-- jb_SirenConfig.lua

TornadoSiren = TornadoSiren or {}

TornadoSiren.Config = {
    SOUND_SCRIPT = "Sound_TornadoSiren",                -- 66s clip
    MODEL_SCRIPT = "TornadoSirenMod.TornadoSiren",
    ANIMATION_NAME = "SirenSpin",
    SPINNY_TILE = "jb_tornadosiren_01_0",
    IDLE_TILE = "jb_tornadosiren_01_1",
    INSTANCE_PREFIX = "jb_tornadosiren_rt_",

    POLE_BOTTOM_SPRITE = "appliances_com_01_88",
    POLE_TOP_SPRITE    = "appliances_com_01_89",

    SPIN_SECONDS = 15.0,    -- real seconds per full rotation
    SPIN_STEPS = 360,       -- frames per rotation
    RUN_SECONDS = 120.0,    -- how many seconds it spins

    SOUND_RADIUS = 200,
    SOUND_VOLUME = 100,

    CHUNK_DIRTY_FLAG = 256, -- the bit doors use
}

function TornadoSiren.locKey(x, y, z)
    return x .. "_" .. y .. "_" .. z
end
