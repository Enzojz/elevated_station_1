function data()
    return {
        info = {
            severityAdd = "NONE",
            severityRemove = "CRITICAL",
            name = _("MOD_NAME"),
            description = _("MOD_DESC"),
            authors = {
                {
                    name = "Enzojz",
                    role = "CREATOR",
                    text = "Idee, Scripting",
                    steamProfile = "enzojz",
                    tfnetId = 27218,
                },
            },
            tags = {"Train Station", "Elevated Station", "Passenger Station", "Station"},
        },
        postRunFn = function(settings, params)
            local tracks = api.res.trackTypeRep.getAll()
            local trackList = {}
            local trackIconList = {}
            local trackNames = {}
            for __, trackName in pairs(tracks) do
                local track = api.res.trackTypeRep.get(api.res.trackTypeRep.find(trackName))
                local pos = #trackList + 1
                if trackName == "standard.lua" then 
                    pos = 1
                elseif trackName == "high_speed.lua" then 
                    pos = trackList[1] == "standard.lua" and 2 or 1
                end
                table.insert(trackList, pos, trackName)
                table.insert(trackIconList, pos, track.icon)
                table.insert(trackNames, pos, track.name)
            end
            
            local con = api.res.constructionRep.get(api.res.constructionRep.find("station/elevated_station.con"))
            for i = 1, #con.params do
                local p = con.params[i]
                local param = api.type.ScriptParam.new()
                param.key = p.key
                param.name = p.name
                if (p.key == "trackType") then
                    param.values = trackNames
                else
                    param.values = p.values
                end
                param.defaultIndex = p.defaultIndex or 0
                param.uiType = p.uiType
                con.params[i] = param
            end
            con.updateScript.fileName = "construction/station/elevated_station.updateFn"
            con.updateScript.params = {
                trackList = trackList,
                trackIconList = trackIconList
            }
        end
    }
end
