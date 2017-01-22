local laneutil = require "laneutil"
local paramsutil = require "paramsutil"
local vec2 = require "vec2"
local func = require "func"
local coor = require "coor"
local line = require "coorline"
local trackEdge = require "trackedge"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {12.5, 15, 17.5, 20}
local segmentLength = 20
local platformWidth = 5
local trackWidth = 5
local trackNumberList = {2, 3, 4, 5, 6, 7, 8, 10, 12}

local newModel = function(m, ...)
    return {
        id = m,
        transf = coor.mul(...)
    }
end

local makeTerminals = function(terminals, side, track)
    return {
        terminals = func.map(terminals, function(t) return {t, side} end),
        vehicleNodeOverride = track * 4 - 2
    }
end

local function generateTrackGroups(xOffsets, xParity, length, height)
    local halfLength = length * 0.5
    return laneutil.makeLanes(func.flatten(
        func.map2(xOffsets, xParity,
            function(xOffset, xPa)
                return xPa == 0 and
                {
                    {{xOffset, -halfLength, height}, {xOffset, 0, height}, {0, 1, 0}, {0, 1, 0}},
                    {{xOffset, 0, height}, {xOffset, halfLength, height}, {0, 1, 0}, {0, 1, 0}}
                }
                or 
                {
                    {{xOffset, halfLength, height}, {xOffset, 0, height}, {0, -1, 0}, {0, -1, 0}},
                    {{xOffset, 0, height}, {xOffset, -halfLength, height}, {0, -1, 0}, {0, -1, 0}}
                }
            end
    )))
end

local function snapRule(n) return function(e) return func.filter(func.seq(0, #e - 1), function(i) return (i > n) and (i - 3) % 4 == 0 end) end end
local noSnap = function(e) return {} end

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
            values = func.map(platformSegments, function(l) return _(tostring(l * segmentLength)) end),
            defaultIndex = 2
        },
        paramsutil.makeTrackTypeParam(),
        paramsutil.makeTrackCatenaryParam(),
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
        {
            key = "tramTrackType",
            name = _("Tram track"),
            values = {_("No"), _("Yes"), _("Electric")}
        }
    }
end

local function buildCoors(nSeg)
    local groupWidth = trackWidth + platformWidth
    
    local function buildUIndex(uOffset, ...) return {func.seq(uOffset * nSeg, (uOffset + 1) * nSeg - 1), {...}} end
    local function build(nbTracks, baseX, xOffsets, uOffsets, xuIndex, xParity)
        if (nbTracks == 0) then
            return xOffsets, uOffsets, xuIndex, xParity
        elseif (nbTracks == 1) then
            return build(nbTracks - 1, baseX + groupWidth - 0.5 * trackWidth,
                func.concat(xOffsets, {baseX + platformWidth}),
                func.concat(uOffsets, {baseX + platformWidth - trackWidth}),
                func.concat(xuIndex, {buildUIndex(#uOffsets, {1, #xOffsets + 1})}),
                func.concat(xParity, {1})
        )
        else
            return build(nbTracks - 2, baseX + groupWidth + trackWidth,
                func.concat(xOffsets, {baseX, baseX + groupWidth}),
                func.concat(uOffsets, {baseX + 0.5 * groupWidth}),
                func.concat(xuIndex, {buildUIndex(#uOffsets, {0, #xOffsets + 1}, {1, #xOffsets + 2})}),
                func.concat(xParity, {0, 1})
        )
        end
    end
    return build
end

local function makeStreet(n, tramTrack)
    
    local lanes = func.mapFlatten(func.seq(1, n - 1), function(n) return {{{n * 5 - 5, 0, 0}, {1, 0, 0}}, {{n * 5, 0, 0}, {1, 0, 0}}} end)
    return {
        {
            type = "STREET",
            params =
            {
                type = "station_new_small.lua",
                tramTrackType = tramTrack
            },
            edges = func.flatten(
                {
                    {
                        {{-30, 0, 0}, {1, 0, 0}},
                        {{-5, 0, 0}, {1, 0, 0}},
                        {{-5, 0, 0}, {1, 0, 0}},
                        {{0, 0, 0}, {1, 0, 0}},
                    },
                    {
                        {{n * 5 - 5, 0, 0}, {1, 0, 0}},
                        {{n * 5, 0, 0}, {1, 0, 0}},
                        {{n * 5, 0, 0}, {1, 0, 0}},
                        {{n * 5 + 25, 0, 0}, {1, 0, 0}},
                    },
                    lanes
                }
            ),
            snapNodes = {0, 7}
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
    local oTop = {x = 0, y = 12.5}
    local oLeft = {x = -config.halfWidth, y = 0}
    local oRight = {x = config.halfWidth, y = 0}
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
            left = line.intersection(line.byRadPt(frad.top(config.baseRadMax), oTop), line.byRadPt(frad.left(config.baseRadMax), oLeft)).x,
            right = line.intersection(line.byRadPt(frad.top(config.baseRadMax), oTop), line.byRadPt(frad.right(config.baseRadMax), oRight)).x,
        }
    }
    
    local function basePts(rad)
        local function makeLines(rad, o)
            return {
                center = line.byRadPt(rad, o),
                outer = line.byRadPt(rad, vec2.add(o, {y = f * math.cos(rad), x = -f * math.sin(rad)})),
                inner = line.byRadPt(rad, vec2.add(o, {y = -f * math.cos(rad), x = f * math.sin(rad)})),
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
        
        pts.top.c.left = line.intersection(lines.top.center, lines.left.center)
        pts.top.c.right = line.intersection(lines.top.center, lines.right.center)
        
        local m = 0.75 * config.height / 15
        pts.right.center.bottom = vec2.add(vec2.mul(m, vec2.sub(oRight, pts.top.c.right)), oRight)
        local lbtm = line.byRadPt(0, pts.right.center.bottom)
        local lbtm2 = line.byRadPt(0, vec2.add(pts.right.center.bottom, {x = 0, y = 1}))
        pts.left.center.bottom = line.intersection(lbtm, lines.left.center)
        
        pts.top.inner.left = line.intersection(lines.top.inner, lines.left.inner)
        pts.top.inner.right = line.intersection(lines.top.inner, lines.right.inner)
        
        lines.top.orth = {}
        lines.top.orth.left = line.byRadPt(rads.top + rad90, pts.top.inner.left)
        lines.top.orth.right = line.byRadPt(rads.top + rad90, pts.top.inner.right)
        
        function make(side)
            pts.top.center[side] = line.intersection(lines.top.center, lines.top.orth[side])
            pts.top.outer[side] = line.intersection(lines.top.outer, lines.top.orth[side])
            pts.top.vert[side] = vec2.mul(0.5, vec2.add(line.intersection(lines.top.center, lines.vert[side]), line.intersection(lines.top.inner, lines.vert[side])))
            pts[side].inner.top = pts.top.inner[side]
            lines[side].orth = line.byRadPt(rads[side] + rad90, pts[side].inner.top)
            pts[side].center.top = line.intersection(lines[side].orth, lines[side].center)
            pts[side].outer.top = line.intersection(lines[side].outer, lines[side].orth)
            pts[side].outer.bottom = line.intersection(lines[side].outer, lbtm)
            pts[side].center.bottomFrame = line.intersection(lines[side].center, lbtm2)
            pts[side].apex = line.intersection(lines[side].outer, lines.top.outer)
            pts[side].hori = vec2.mul(0.5, vec2.add(line.intersection(lines[side].center, lines.hori), line.intersection(lines[side].inner, lines.hori)))
        end
        make("left")
        make("right")
        return pts
    end
    
    local function transformRoof(pts)
        local pt0, pt1 = table.unpack(pts)
        local o = coor.nmul(0.5, coor.add(pt0, pt1))
        local vec = coor.sub(pt0, pt1)
        local length = coor.length(vec)
        local rad = (vec.z > 0 and 1 or -1) * math.acos(vec.x / length)
        return o, length, rad
    end
    
    local function vec2vec3(y) return function(pt) return {x = pt.x, y = y, z = pt.y} end end
    
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
        local function rad(v) return (v.y > 0 and 1 or -1) * math.acos(v.x / vec2.length(v)) end
        local function distVec(apex, outer) return vec2.normalize(vec2.sub(apex, outer)), vec2.distance(apex, outer) end
        
        local function makeAngle(o, apex, cw, ccw)
            local vecCW, distCW = distVec(apex, ccw)
            local vecCCW, distCCW = distVec(apex, cw)
            local mPos = coor.trans({x = config.oX + o.x, y = y, z = config.height + o.y})
            return {
                coor.mul(coor.scaleX(-distCW), coor.rotY(rad(vecCW)), mPos),
                coor.mul(coor.scaleX(distCCW), coor.rotY(rad(vecCCW) - math.pi), mPos)}
        end
        return func.flatten({
            makeAngle(pts.left.inner.top, pts.left.apex, pts.top.outer.left, pts.left.outer.top),
            makeAngle(pts.right.inner.top, pts.right.apex, pts.right.outer.top, pts.top.outer.right)
        })
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
        o = coor.add(o, coor.nmul(length + 1, {x = -math.cos(rad), y = 0, z = -math.sin(rad)}))
        return coor.mul(coor.scaleX(2), coor.rotY(rad), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
    end
    
    local function transformTube(pts)
        local pt0, pt1 = table.unpack(pts)
        local o = coor.nmul(0.5, coor.add(pt0, pt1))
        local vec = coor.sub(pt0, pt1)
        local length = coor.length(vec)
        local radX = (vec.z > 0 and -1 or 1) * math.acos(vec.y / math.sqrt(vec.z * vec.z + vec.y * vec.y))
        local radZ = (vec.x > 0 and -1 or 1) * math.acos(vec.y / math.sqrt(vec.x * vec.x + vec.y * vec.y))
        return coor.mul(coor.scaleY(length), coor.rotX(radX), coor.rotZ(radZ), coor.trans(o), coor.transZ(config.height), coor.transX(config.oX))
    end
    
    local function mRoofTubes(params)
        local lPts, rPts, y = table.unpack(params)
        return func.map(
            func.map({
                {lPts.top.vert.left, rPts.top.vert.left},
                {lPts.top.vert.right, rPts.top.vert.right},
                {lPts.left.hori, rPts.left.hori},
                {lPts.right.hori, rPts.right.hori},
                {vec2.mul(0.5, vec2.add(lPts.top.c.left, lPts.top.inner.left)), vec2.mul(0.5, vec2.add(rPts.top.c.left, rPts.top.inner.left))},
                {vec2.mul(0.5, vec2.add(lPts.top.c.right, lPts.top.inner.right)), vec2.mul(0.5, vec2.add(rPts.top.c.right, rPts.top.inner.right))},
            }, function(pts) return {vec2vec3(y)(pts[1]), vec2vec3(y + config.span)(pts[2])} end)
            , transformTube)
    end
    
    local function mEntryTubes(params)
        local oL, lengthL, radL = transformEntry(params[1])
        local oR, lengthR, radR = transformEntry(params[2])
        
        oL = coor.add(oL, coor.nmul(lengthL + 1, {x = -math.cos(radL), y = 0, z = -math.sin(radL)}))
        oR = coor.add(oR, coor.nmul(lengthR + 1, {x = -math.cos(radR), y = 0, z = -math.sin(radR)}))
        return coor.mul(transformTube({oL, oR}), coor.transZ(0.75))
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
            
            local result = {}
            
            local trackType = ({"standard.lua", "high_speed.lua"})[params.trackType + 1]
            local catenary = params.catenary == 1
            local nSeg = platformSegments[params.length + 1]
            local length = nSeg * segmentLength
            local nbTracks = trackNumberList[params.nbTracks + 1]
            local height = heightList[params.platformHeight + 1]
            local hasClassicRoofs = params.roofStyle == 2
            local tramTrack = ({"NO", "YES", "ELECTRIC"})[(params.tramTrackType == nil and 0 or params.tramTrackType) + 1]
            
            local xOffsets, uOffsets, xuIndex, xParity = buildCoors(nSeg)(nbTracks, 0, {}, {}, {}, {})
            
            local normal = generateTrackGroups(xOffsets, xParity, length, height)
            local ext1 = coor.applyEdges(coor.transY(length * 0.5 + 5), coor.I())(generateTrackGroups(xOffsets, func.seqMap({1, #xOffsets}, function(_) return 0 end), 10, height))
            local ext2 = coor.applyEdges(coor.flipY(), coor.flipY())(ext1)
            
            local roofConfig = function()
                return {
                    halfWidth = (xOffsets[#xOffsets] - xOffsets[1] + 10) * 0.5,
                    oX = (xOffsets[#xOffsets] + xOffsets[1]) * 0.5,
                    span = ({1, 2, 2})[(params.roofStyle + 1 or 1)],
                    roofLength = hasClassicRoofs and 0 or ({0, 0.25, 0.5, 0.75, 1})[params.roofLength + 1] * length,
                    baseRadMax = 15 * math.pi / 180,
                    framesPerCycle = 25,
                    nbTracks = nbTracks,
                    height = height,
                }
            end
            
            result.edgeLists = func.flatten(
                {
                    {
                        trackEdge.bridge(catenary, trackType, "z_elevated_station.lua", snapRule(#normal))(func.flatten({normal, ext1, ext2})),
                        trackEdge.bridge(false, "zzz_mock_elevated_station.lua", "z_elevated_station.lua", noSnap)(generateTrackGroups(uOffsets, func.seqMap({1, #uOffsets}, function(_) return 0 end), length, height)),
                    },
                    makeStreet(#xOffsets + #uOffsets, tramTrack)
                })
            
            
            result.models =
                func.flatten(
                    {
                        func.mapFlatten(uOffsets,
                            function(xOffset)
                                return func.map2(func.seq(1, nSeg), platformPatterns(nSeg), function(i, p)
                                    return newModel(p, coor.transY(i * segmentLength - 0.5 * (segmentLength + length)), coor.transX(xOffset), coor.transZ(0.3 + height)) end
                            )
                            end),
                        func.mapFlatten(hasClassicRoofs and uOffsets or {},
                            function(xOffset)
                                return func.map2(func.seq(1, nSeg), roofPatterns(nSeg), function(i, p)
                                    return newModel(p, coor.transY(i * segmentLength - 0.5 * (segmentLength + length)), coor.transX(xOffset), coor.transZ(0.3 + height)) end
                            )
                            end),
                        makeRoof(roofConfig()),
                        makeEntry(height, length, #xOffsets + #uOffsets)
                    })
            
            result.terminalGroups = func.mapFlatten(xuIndex, function(v)
                local u, xIndices = table.unpack(v)
                return func.map(xIndices, function(x) return makeTerminals(u, table.unpack(x)) end
            )
            end)
            
            local l = -5
            local r = -2.5 + (#xOffsets * trackWidth + #uOffsets * platformWidth) + 2.5
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
                    name = _("Underground / Multi-level Passenger Station"),
                    description = _("An underground / multi-level passenger station")
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
