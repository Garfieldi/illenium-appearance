-- Randomizer module for illenium-appearance
-- Adapted from example provided in the issue
local FATHERS = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 42, 43, 44 }
local MOTHERS = { 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 45 }
local NATURAL_HAIR_COLORS = 29
local NATURAL_EYE_COLORS = 7
local FEATURE_SPREAD = 0.5

local function pick(list)
    return list[math.random(#list)]
end

local function chance(probability)
    return math.random() < probability
end

local function between(low, high)
    return low + (high - low) * math.random()
end

local function round(value)
    return math.floor(value * 100 + 0.5) / 100
end

local function overlay(id, opacityLow, opacityHigh, color)
    local count = GetPedHeadOverlayNum(id)
    if not count or count <= 0 then return nil end
    return {
        style = math.random(0, count - 1),
        opacity = round(between(opacityLow, opacityHigh)),
        color = color or 0,
        secondColor = color or 0,
    }
end

local randomizer = {}

---@param ped number
---@return table
function randomizer.features(ped)
    local female = GetEntityModel(ped) == `mp_f_freemode_01`
    local father = pick(FATHERS)
    local mother = pick(MOTHERS)
    local hairColor = math.random(0, math.min(NATURAL_HAIR_COLORS, math.max(0, GetNumHairColors() - 1)))
    local makeupColors = math.max(1, GetNumMakeupColors())

    local faceFeaturesArray = {}
    for i = 1, 20 do
        faceFeaturesArray[i] = round((math.random() + math.random() - 1.0) * FEATURE_SPREAD)
    end

    -- Map face features array to named dict
    local faceFeatures = {}
    for i = 1, #constants.FACE_FEATURES do
        local name = constants.FACE_FEATURES[i]
        faceFeatures[name] = faceFeaturesArray[i] or 0.0
    end

    -- Build headOverlays with named keys
    local headOverlays = {}

    -- Eyebrows is almost always present (id 2)
    local eyebrows = overlay(2, 0.8, 1.0, hairColor)
    if eyebrows then headOverlays["eyebrows"] = eyebrows end

    if chance(0.25) then
        local v = overlay(0, 0.3, 0.8)
        if v then headOverlays["blemishes"] = v end
    end
    if chance(0.3) then
        local v = overlay(3, 0.2, 0.6)
        if v then headOverlays["ageing"] = v end
    end
    if chance(0.2) then
        local v = overlay(6, 0.3, 0.8)
        if v then headOverlays["complexion"] = v end
    end
    if chance(0.15) then
        local v = overlay(7, 0.2, 0.6)
        if v then headOverlays["sunDamage"] = v end
    end
    if chance(0.2) then
        local v = overlay(9, 0.3, 0.9)
        if v then headOverlays["moleAndFreckles"] = v end
    end
    if chance(0.15) then
        local v = overlay(11, 0.3, 0.8)
        if v then headOverlays["bodyBlemishes"] = v end
    end

    if female then
        if chance(0.35) then
            local v = overlay(4, 0.4, 0.9, math.random(0, makeupColors - 1))
            if v then headOverlays["makeUp"] = v end
        end
        if chance(0.3) then
            local v = overlay(5, 0.3, 0.7, math.random(0, makeupColors - 1))
            if v then headOverlays["blush"] = v end
        end
        if chance(0.4) then
            local v = overlay(8, 0.5, 1.0, math.random(0, makeupColors - 1))
            if v then headOverlays["lipstick"] = v end
        end
    else
        if chance(0.6) then
            local v = overlay(1, 0.6, 1.0, hairColor)
            if v then headOverlays["beard"] = v end
        end
        if chance(0.4) then
            local v = overlay(10, 0.5, 1.0, hairColor)
            if v then headOverlays["chestHair"] = v end
        end
    end

    -- Ensure all overlay types exist with default values if not randomized
    -- This prevents nils when setting appearance
    for _, name in ipairs(constants.HEAD_OVERLAYS) do
        if not headOverlays[name] then
            headOverlays[name] = { style = 0, opacity = 0.0, color = 0, secondColor = 0 }
        end
    end

    local hairCount = GetNumberOfPedDrawableVariations(ped, 2)

    return {
        headBlend = {
            shapeFirst = father, shapeSecond = mother, shapeThird = 0,
            skinFirst = father, skinSecond = mother, skinThird = 0,
            shapeMix = round(female and between(0.5, 0.95) or between(0.05, 0.5)),
            skinMix = round(math.random()),
            thirdMix = 0.0,
        },
        faceFeatures = faceFeatures,
        headOverlays = headOverlays,
        eyeColor = math.random(0, NATURAL_EYE_COLORS),
        hair = {
            style = hairCount > 0 and math.random(0, hairCount - 1) or 0,
            texture = 0,
            color = hairColor,
            highlight = hairColor,
        },
    }
end

---@param ped number
---@return boolean applied false when the ped is not a freemode model
function randomizer.apply(ped)
    if not client.isPedFreemodeModel(ped) then return false end
    for i = 0, 12 do
        SetPedHeadOverlay(ped, i, 255, 0.0)
    end
    local feat = randomizer.features(ped)
    -- Apply using client setters
    client.setPedHeadBlend(ped, feat.headBlend)
    client.setPedFaceFeatures(ped, feat.faceFeatures)
    client.setPedHeadOverlays(ped, feat.headOverlays)
    client.setPedEyeColor(ped, feat.eyeColor)
    -- For hair we need tattoos as second param (current tattoos)
    local tattoos = client.getPedTattoos()
    client.setPedHair(ped, feat.hair, tattoos)
    return true
end

client.randomizer = randomizer
