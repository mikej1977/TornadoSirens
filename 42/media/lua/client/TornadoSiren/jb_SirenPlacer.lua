-- jb_SirenPlacer.lua

require "TornadoSiren/jb_SirenConfig"
require "TornadoSiren/jb_SirenController"

local Config = TornadoSiren.Config

local SIREN_Z_OFFSET = 2

local function placeSiren(square)
    if not square then return end
    local cell = getCell()
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local poleTopSq = cell:getOrCreateGridSquare(x, y, z + 1)
    local sirenSq = cell:getOrCreateGridSquare(x, y, z + SIREN_Z_OFFSET)

    local poleBottom = IsoObject.new(cell, square, Config.POLE_BOTTOM_SPRITE)
    local poleTop = IsoObject.new(cell, poleTopSq, Config.POLE_TOP_SPRITE)
    square:AddTileObject(poleBottom)
    poleTopSq:AddTileObject(poleTop)
    poleBottom:transmitCompleteItemToServer()
    poleTop:transmitCompleteItemToServer()

    local siren = IsoObject.new(cell, sirenSq, Config.IDLE_TILE)
    siren:getModData().isTornadoSiren = true
    sirenSq:AddTileObject(siren)
    TornadoSirenClient.attachSiren(siren)
    siren:transmitCompleteItemToServer()

    TornadoSirenClient.requestRegister(x, y, z + SIREN_Z_OFFSET)

    square:RecalcProperties()
    square:RecalcAllWithNeighbours(true)
end

local function OnPreFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local square = nil
    for _, v in ipairs(worldobjects) do square = v:getSquare() break end
    if not square then return end

    local sirenSq = getCell():getGridSquare(square:getX(), square:getY(), square:getZ() + SIREN_Z_OFFSET)
    local siren = TornadoSirenClient.getSirenObject(sirenSq)
    if siren then
        local sq = siren:getSquare()
        if TornadoSirenClient.isActive(sq:getX(), sq:getY(), sq:getZ()) then
            context:addOption("Stop Siren", nil, function() TornadoSirenClient.requestStop(sq:getX(), sq:getY(), sq:getZ()) end)
        else
            context:addOption("Start Siren", nil, function() TornadoSirenClient.requestStart(sq:getX(), sq:getY(), sq:getZ()) end)
        end
    else
        context:addOption("Place Siren", square, placeSiren)
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(OnPreFillWorldObjectContextMenu)
