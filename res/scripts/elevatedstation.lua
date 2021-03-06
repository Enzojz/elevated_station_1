local laneutil = require "laneutil"
local paramsutil = require "paramsutil"
local func = require "elevatedstation/func"
local pipe = require "elevatedstation/pipe"
local coor = require "elevatedstation/coor"
local line = require "elevatedstation/coorline"
local trackEdge = require "elevatedstation/trackedge"
local station = require "elevatedstation/stationlib"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {12.5, 15, 17.5, 20}
local trackNumberList = {2, 3, 4, 5, 6, 7, 8, 10, 12}

local newModel = function(m, ...)
    return {
        id = m,
        transf = coor.mul(...)
    }
end

local function snapRule(n) return function(e) return func.filter(func.seq(0, #e - 1), function(i) return (i > n) and (i - 3) % 4 == 0 end) end end

local function params()
    return {
        {
            key = "nbTracks",
            name = _("Number of tracks"),
            values = func.map(trackNumberList, tostring),
        },
        {
            key = "length",
            name = _("Platform length") .. "(m)",
            values = func.map(platformSegments, function(l) return _(tostring(l * station.segmentLength)) end),
            defaultIndex = 2
        },
        paramsutil.makeTrackTypeParam(),
        paramsutil.makeTrackCatenaryParam(),
        {
            key = "trackLayout",
            name = _("Track Layout"),
            values = func.map({1, 2, 3, 4}, tostring),
            defaultIndex = 0
        },
        {
            key = "platformHeight",
            name = _("Station height") .. "(m)",
            values = func.map(heightList, tostring),
            defaultIndex = 1
        },
        {
            key = "roofLength",
            name = "Roof length",
            values = {_("No roof"), _("1/4"), _("1/2"), _("3/4"), _("Full")},
            defaultIndex = 3
        },
        {
            key = "roofStyle",
            name = "Roof frame Density",
            values = {_("Normal"), _("Less dense"), ("Simple")}
        },
        paramsutil.makeTramTrackParam1(),
        paramsutil.makeTramTrackParam2()
    }
end


local function makeStreet(n, tramTrack)
    local l = n * 5 - 15
    return {
        {
            type = "STREET",
            params =
            {
                type = "station_new_small.lua",
                tramTrackType = tramTrack
            },
            edges = func.flatten({
                {
                    {{5, 0, 0}, {-15, 0, 0}},
                    {{-10, 0, 0}, {-15, 0, 0}},
                    {{-10, 0, 0}, {-20, 0, 0}},
                    {{-30, 0, 0}, {-20, 0, 0}},
                    
                    {{l + 5, 0, 0}, {15, 0, 0}},
                    {{l + 20, 0, 0}, {15, 0, 0}},
                    {{l + 20, 0, 0}, {20, 0, 0}},
                    {{l + 40, 0, 0}, {20, 0, 0}},
                },
                (l == 0) and {} or
                {
                    {{5, 0, 0}, {l, 0, 0}},
                    {{l + 5, 0, 0}, {l, 0, 0}},
                }
            }
            ),
            snapNodes = {3, 7}
        }
    }
end

local function makeEntry(height, length, n)
    local suffix = math.floor(height)
    local profile =
        {
            gate = "station/train/passenger/elevated_station/entry_" .. suffix .. ".mdl",
            rep = "station/train/passenger/elevated_station/entry_rep_" .. suffix .. ".mdl",
            stairs = "station/train/passenger/elevated_station/entry_stairs_" .. suffix .. ".mdl",
        }
    
    local gates = func.seqMap({0, n - 1}, function(n) return newModel(profile.rep, coor.transX(n * 5)) end)
    gates[2] = newModel(profile.stairs, coor.transX(5))
    gates[n - 1] = newModel(profile.stairs, coor.transX((n - 2) * 5))
    gates[1] = newModel(profile.gate, coor.flipX())
    gates[n] = newModel(profile.gate, coor.transX((n - 1) * 5))
    return gates
end

local function makeRoof(config)
    local oTop = coor.xy(0, 12.5)
    local oLeft = coor.xy(-config.halfWidth, 0)
    local oRight = coor.xy(config.halfWidth, 0)
    local rad90 = math.pi * 0.5
    local f = 0.75
    
    config.frame = "station/train/passenger/elevated_station/frame.mdl"
    config.angle = "station/train/passenger/elevated_station/angle.mdl"
    config.glass = "station/train/passenger/elevated_station/glass.mdl"
    config.entryXtr = "station/train/passenger/elevated_station/entry_xtr.mdl"
    config.tube = "station/train/passenger/elevated_station/tube.mdl"
    config.steps = config.roofLength / config.span
    
    local frad = {
        top = function(rad) return rad * 0.75 / (math.log(config.nbTracks, 4)) end,
        left = function(rad) return rad90 - rad * 1.2 end,
        right = function(rad) return rad90 + rad * 1.2 end
    }
    
    tubeLimit = {
        top = {
            left = (line.byRadPt(frad.top(config.baseRadMax), oTop) - line.byRadPt(frad.left(config.baseRadMax), oLeft)).x,
            right = (line.byRadPt(frad.top(config.baseRadMax), oTop) - line.byRadPt(frad.right(config.baseRadMax), oRight)).x,
        }
    }
    
    local function basePts(rad)
        local function makeLines(rad, o)
            return {
                center = line.byRadPt(rad, o),
                outer = line.byRadPt(rad, o + coor.xy(-f * math.sin(rad), f * math.cos(rad))),
                inner = line.byRadPt(rad, o + coor.xy(f * math.sin(rad), -f * math.cos(rad))),
            }
        end
        
        
        local rads = {
            top = frad.top(rad),
            left = frad.left(rad),
            right = frad.right(rad)
        }
        
        local lines = {
            top = makeLines(rads.top, oTop),
            left = makeLines(rads.left, oLeft),
            right = makeLines(rads.right, oRight),
            hori = line.byRadPt(0, {x = 0, y = -1}),
            vert = {
                left = line.byRadPt(rad90, {x = tubeLimit.top.left * 0.6, y = 0}),
                right = line.byRadPt(rad90, {x = tubeLimit.top.right * 0.6, y = 0}),
            }
        }
        
        local pts = {
            top = {c = {}, center = {}, outer = {}, inner = {}, vert = {}},
            left = {center = {}, outer = {}, inner = {}},
            right = {center = {}, outer = {}, inner = {}}
        }
        
        lines.right.outer, lines.right.inner = lines.right.inner, lines.right.outer
        
        pts.top.c.left = lines.top.center - lines.left.center
        pts.top.c.right = lines.top.center - lines.right.center
        
        local m = 0.75 * config.height / 15
        pts.right.center.bottom = (oRight - pts.top.c.right) * m + oRight
        local lbtm = line.byRadPt(0, pts.right.center.bottom)
        local lbtm2 = line.byRadPt(0, pts.right.center.bottom + coor.xy(0, 1))
        pts.left.center.bottom = lbtm - lines.left.center
        
        pts.top.inner.left = lines.top.inner - lines.left.inner
        pts.top.inner.right = lines.top.inner - lines.right.inner
        
        lines.top.orth = {}
        lines.top.orth.left = line.byRadPt(rads.top + rad90, pts.top.inner.left)
        lines.top.orth.right = line.byRadPt(rads.top + rad90, pts.top.inner.right)
        
        function make(side)
            pts.top.center[side] = lines.top.center - lines.top.orth[side]
            pts.top.outer[side] = lines.top.outer - lines.top.orth[side]
            pts.top.vert[side] = ((lines.top.center - lines.vert[side]) + (lines.top.inner - lines.vert[side])) * 0.5
            pts[side].inner.top = pts.top.inner[side]
            lines[side].orth = line.byRadPt(rads[side] + rad90, pts[side].inner.top)
            pts[side].center.top = lines[side].orth - lines[side].center
            pts[side].outer.top = lines[side].outer - lines[side].orth
            pts[side].outer.bottom = lines[side].outer - lbtm
            pts[side].center.bottomFrame = lines[side].center - lbtm2
            pts[side].apex = lines[side].outer - lines.top.outer
            pts[side].hori = ((lines[side].center - lines.hori) + (lines[side].inner - lines.hori)) * 0.5
        end
        make("left")
        make("right")
        return pts
    end
    
    local function transformRoof(pts)
        local pt0, pt1 = table.unpack(pts)
        local o = (pt0 + pt1) * 0.5
        local vec = pt0 - pt1
        local length = vec:length()
        local rad = (vec.z > 0 and 1 or -1) * math.acos(vec.x / length)
        return o, length, rad
    end
    
    local function vec2vec3(y) return function(pt) return coor.xyz(pt.x, y, pt.y) end end
    
    local function mFrame(params)
        local pts, y = table.unpack(params)
        local function tr(pts)
            local o, length, rad = transformRoof(pts)
            return coor.mul(coor.scaleX(length), coor.rotY(rad), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
        end
        return func.map({{pts.top.center.left, pts.top.center.right}, {pts.left.center.top, pts.left.center.bottom}, {pts.right.center.top, pts.right.center.bottom}},
            function(pts) return tr(func.map(pts, vec2vec3(y))) end)
    end
    
    local function mGlass(params)
        local pts, y = table.unpack(params)
        local function tr(pts)
            local o, length, rad = transformRoof(pts)
            return coor.mul(coor.scaleZ(config.span), coor.rotX(rad90), coor.scaleX(length), coor.rotY(rad), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
        end
        return func.map({{pts.top.c.left, pts.top.c.right}, {pts.top.c.left, pts.left.center.bottomFrame}, {pts.top.c.right, pts.right.center.bottomFrame}},
            function(pts) return tr(func.map(pts, vec2vec3(y))) end)
    end
    
    local function mGlassBottom(params)
        local pts, y = table.unpack(params)
        local function tr(pts)
            local o, length, rad = transformRoof(pts)
            return coor.mul(coor.transX(0.5), coor.scaleZ(config.span / 1.5), coor.rotX(rad90), coor.scaleX(0.5), coor.rotY(rad), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
        end
        return func.map({{pts.left.center.bottomFrame, pts.left.center.bottom}, {pts.right.center.bottomFrame, pts.right.center.bottom}},
            function(pts) return tr(func.map(pts, vec2vec3(y))) end)
    end
    
    local function mAngles(params)
        local pts, y = table.unpack(params)
        local function rad(v) return (v.y > 0 and 1 or -1) * math.acos(v.x / v:length()) end
        local function distVec(apex, outer) return (apex - outer):normalized(), (apex % outer) end
        
        local function makeAngle(o, apex, cw, ccw)
            local vecCW, distCW = distVec(apex, ccw)
            local vecCCW, distCCW = distVec(apex, cw)
            local mPos = coor.trans(coor.xyz(config.oX + o.x, y, config.height + o.y))
            return {
                coor.mul(coor.scaleX(-distCW), coor.rotY(rad(vecCW)), mPos),
                coor.mul(coor.scaleX(distCCW), coor.rotY(rad(vecCCW) - math.pi), mPos)}
        end
        return func.concat(
            makeAngle(pts.left.inner.top, pts.left.apex, pts.top.outer.left, pts.left.outer.top),
            makeAngle(pts.right.inner.top, pts.right.apex, pts.right.outer.top, pts.top.outer.right)
    )
    end
    
    local function transformEntry(params)
        local pts, vCos, y = table.unpack(params)
        local o = vec2vec3(y)(pts.left.outer.bottom)
        local length = vCos * 20
        local rad = math.rad(-10)
        return o, length, rad
    end
    
    local function mEntry(params)
        local o, length, rad = transformEntry(params)
        return coor.mul(coor.transX(-0.5), coor.scaleX(length + 1), coor.transZ(0.75), coor.rotY(rad), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
    end
    
    local function mEntryGlass(params)
        local o, length, rad = transformEntry(params)
        return coor.mul(coor.scaleZ(config.span), coor.rotX(rad90), coor.transX(-0.5), coor.scaleX(length), coor.transZ(0.75), coor.rotY(rad), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
    end
    
    local function mEntryExtreme(params)
        local o, length, rad = transformEntry(params)
        o = coor.xyz(-math.cos(rad), 0, -math.sin(rad)) * (length + 1) + o
        return coor.mul(coor.scaleX(2), coor.rotY(rad), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
    end
    
    local function transformTube(pts)
        local pt0, pt1 = table.unpack(pts)
        local o = (pt0 + pt1) * 0.5
        local vec = pt0 - pt1
        local length = vec:length()
        local radX = (vec.z > 0 and -1 or 1) * math.acos(vec.y / math.sqrt(vec.z * vec.z + vec.y * vec.y))
        local radZ = (vec.x > 0 and -1 or 1) * math.acos(vec.y / math.sqrt(vec.x * vec.x + vec.y * vec.y))
        return coor.scaleY(length) * coor.rotX(radX) * coor.rotZ(radZ) * coor.trans(o) * coor.transZ(config.height) * coor.transX(config.oX)
    end
    
    local function mRoofTubes(params)
        local lPts, rPts, y = table.unpack(params)
        return func.map(
            func.map({
                {lPts.top.vert.left, rPts.top.vert.left},
                {lPts.top.vert.right, rPts.top.vert.right},
                {lPts.left.hori, rPts.left.hori},
                {lPts.right.hori, rPts.right.hori},
                {(lPts.top.c.left + lPts.top.inner.left) * 0.5, (rPts.top.c.left + rPts.top.inner.left) * 0.5},
                {(lPts.top.c.right + lPts.top.inner.right) * 0.5, (rPts.top.c.right + rPts.top.inner.right) * 0.5},
            }, function(pts) return {vec2vec3(y)(pts[1]), vec2vec3(y + config.span)(pts[2])} end)
            , transformTube)
    end
    
    local function mEntryTubes(params)
        local oL, lengthL, radL = transformEntry(params[1])
        local oR, lengthR, radR = transformEntry(params[2])
        
        oL = coor.xyz(-math.cos(radL), 0, -math.sin(radL)) * (lengthL + 1) + oL
        oR = coor.xyz(-math.cos(radR), 0, -math.sin(radR)) * (lengthR + 1) + oR
        return transformTube({oL, oR}) * coor.transZ(0.75)
    end
    
    local function phase(y) return y * 4 * rad90 / config.framesPerCycle end
    local function rad(y) return -math.cos(phase(y)) * config.baseRadMax end
    
    local seqRoof = func.seq(math.ceil(-0.5 * config.steps), math.floor(0.5 * config.steps))
    local seqEntry = func.seq(math.ceil(-config.framesPerCycle / 2), math.floor(config.framesPerCycle / 2))
    local dephasing = function(seq) local s = func.map(seq, function(y) return y + 0.5 end); table.remove(s); return s end
    
    local gPt1 = func.map(seqRoof, function(y) return {basePts(rad(y)), y * config.span} end)
    local gPt2 = func.map(dephasing(seqRoof), function(y) return {basePts(rad(y)), y * config.span} end)
    local gPt3 = func.map(seqEntry, function(y) return {basePts(rad(y)), math.cos(phase(y) / 2), y * config.span} end)
    local gPt4 = func.map(dephasing(seqEntry), function(y) return {basePts(rad(y)), math.cos(phase(y) / 2), y * config.span} end)
    
    local gPt5 = func.map2(func.range(gPt1, 1, #gPt1 - 1), func.range(gPt1, 2, #gPt1), function(l, r) return {l[1], r[1], l[2]} end)
    local gPt6 = func.map2(func.range(gPt3, 1, #gPt3 - 1), func.range(gPt3, 2, #gPt3), function(l, r) return {l, r} end)
    
    return config.roofLength ~= 0 and func.flatten(
        {
            func.mapFlatten(func.map(gPt1, mFrame), function(m) return func.map(m, func.bind(newModel, config.frame)) end),
            func.mapFlatten(func.map(gPt2, mGlass), function(m) return func.map(m, func.bind(newModel, config.glass)) end),
            func.mapFlatten(func.map(gPt2, mGlassBottom), function(m) return func.map(m, func.bind(newModel, config.frame)) end),
            func.mapFlatten(func.map(gPt1, mAngles), function(m) return func.map(m, func.bind(newModel, config.angle)) end),
            func.mapFlatten(func.map(gPt5, mRoofTubes), function(m) return func.map(m, func.bind(newModel, config.tube)) end),
            func.map(func.map(gPt3, mEntry), func.bind(newModel, config.frame)),
            func.map(func.map(gPt3, mEntryExtreme), func.bind(newModel, config.entryXtr)),
            func.map(func.map(gPt4, mEntryGlass), func.bind(newModel, config.glass)),
            func.map(func.map(gPt6, mEntryTubes), func.bind(newModel, config.tube)),
            {
                newModel(config.frame, coor.rotX(rad90), coor.scaleX(config.roofLength), coor.transZ(config.height), coor.rotZ(rad90), coor.transX(config.oX + config.halfWidth - 0.75)),
                newModel(config.frame, coor.rotX(rad90), coor.scaleX(config.roofLength), coor.transZ(config.height), coor.rotZ(rad90), coor.transX(config.oX - config.halfWidth + 0.75)),
            }
        }) or {}

end

local function defaultParams(params)
    params.trackType = params.trackType or 0
    params.catenary = params.catenary or 1
    params.length = params.length or 2
    params.nbTracks = params.nbTracks or 0
    params.platformHeight = params.platformHeight or 1
    params.roofLength = params.roofLength or 3
    params.roofStyle = params.roofStyle or 0
    params.tramTrack = params.tramTrack or 0
    params.trackLayout = params.trackLayout or 0
end

local function updateFn(config)
    
    local platformPatterns = function(n)
        local basicPattern = {config.platformRepeat, config.platformDwlink}
        local platforms = func.mapFlatten(func.seq(1, n * 0.5), function(i) return basicPattern end)
        platforms[1] = config.platformStart
        platforms[n] = config.platformEnd
        return n > 2 and platforms or {config.platformDwlink, config.platformEnd}
    end
    
    local roofPatterns = function(n)
        local roofs = func.seqMap({1, n}, function(_) return config.platformRoofRepeat end)
        if (n > 2) then
            roofs[1] = config.platformRoofStart
            roofs[n] = config.platformRoofEnd
        end
        return roofs
    end
    
    return
        function(params)
            defaultParams(params)
            local result = {}
            
            local trackType = ({"standard.lua", "high_speed.lua"})[params.trackType + 1]
            local catenary = params.catenary == 1
            local nSeg = platformSegments[params.length + 1]
            local length = nSeg * station.segmentLength
            local nbTracks = trackNumberList[params.nbTracks + 1]
            local height = heightList[params.platformHeight + 1]
            local hasClassicRoofs = params.roofStyle == 2
            local tramTrack = ({"NO", "YES", "ELECTRIC"})[params.tramTrack + 1]
            
            local levels = {
                {
                    mz = coor.transZ(height),
                    mr = coor.I(),
                    mdr = coor.I(),
                    id = 1,
                    nbTracks = nbTracks,
                    baseX = 0,
                    ignoreFst = ({true, false, true, false})[params.trackLayout + 1],
                    ignoreLst = (nbTracks % 2 == 0 and {false, false, true, true} or {true, true, false, false})[params.trackLayout + 1],
                }
            }
            
            
            local xOffsets, uOffsets, xuIndex, xParity = station.buildCoors(nSeg)(levels, {}, {}, {}, {})
            
            local function resetParity(offset)
                return {
                    mpt = offset.mpt,
                    mvec = offset.mvec,
                    parity = coor.I(),
                    id = offset.id,
                    x = offset.x
                }
            end
            
            local normal = station.generateTrackGroups(xOffsets, length)
            local ext1 = coor.applyEdges(coor.transY(length * 0.5 + 5), coor.I())(station.generateTrackGroups(func.map(xOffsets, resetParity), 10))
            local ext2 = coor.applyEdges(coor.flipY(), coor.flipY())(ext1)
            
            local offsets = func.flatten({xOffsets, uOffsets})
            table.sort(offsets, function(l, r) return l.x < r.x end)
            local roofConfig = function()
                return {
                    halfWidth = (offsets[#offsets].x - offsets[1].x + 10) * 0.5,
                    oX = (offsets[#offsets].x + offsets[1].x) * 0.5,
                    span = ({1, 2, 2})[(params.roofStyle + 1 or 1)],
                    roofLength = hasClassicRoofs and 0 or ({0, 0.25, 0.5, 0.75, 1})[params.roofLength + 1] * length,
                    baseRadMax = 15 * math.pi / 180,
                    framesPerCycle = 25,
                    nbTracks = nbTracks,
                    height = height,
                }
            end
            
            result.edgeLists = pipe.new
                / trackEdge.bridge(catenary, trackType, "z_elevated_station.lua", snapRule(#normal))(func.flatten({normal, ext1, ext2}))
                / trackEdge.bridge(false, "zzz_mock_elevated_station.lua", "z_elevated_station.lua", station.noSnap)(station.generateTrackGroups(uOffsets, length))
                + makeStreet(#xOffsets + #uOffsets, tramTrack)
            
            result.models = pipe.new
                + station.makePlatforms(uOffsets, platformPatterns(nSeg), coor.transZ(0.3))
                + (hasClassicRoofs and station.makePlatforms(uOffsets, roofPatterns(nSeg)) or makeRoof(roofConfig()))
                + makeEntry(height, length, #xOffsets + #uOffsets)
            
            result.terminalGroups = station.makeTerminals(xuIndex)
            
            local l = -5
            local r = -2.5 + (#xOffsets * station.trackWidth + #uOffsets * station.platformWidth) + 2.5
            local e = 0.5 * length + 20
            local f = {{l, -35, 0}, {r, -35, 0}, {r, 35, 0}, {l, 35, 0}}
            
            result.terrainAlignmentLists = {
                {
                    type = "EQUAL",
                    faces = {f},
                },
                {
                    type = "LESS",
                    faces = {
                        {{l, -e, height}, {r, -e, height}, {r, e, height}, {l, e, height}}
                    },
                },
            }
            
            result.groundFaces = {
                {face = f, modes = {{type = "FILL", key = "industry_gravel_small_01"}}},
                {face = f, modes = {{type = "STROKE_OUTER", key = "building_paving"}}}
            }
            
            result.cost = 60000 + nbTracks * 24000
            result.maintenanceCost = result.cost / 6
            
            return result
        end
end


local elevatedstation = {
    dataCallback = function(config)
        return function()
            return {
                type = "RAIL_STATION",
                description = {
                    name = _("Elevated Train Station"),
                    description = _("An elevated train station")
                },
                availability = config.availability,
                order = config.order,
                soundConfig = config.soundConfig,
                params = params(),
                updateFn = updateFn(config)
            }
        end
    end
}

return elevatedstation
