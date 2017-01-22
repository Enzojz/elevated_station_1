local path = "station/train/passenger/elevated_station/"
function data()
	return {
		name = _("Elevated Station Viaduct"),

		yearFrom = 1990,
		yearTo = 0,

		carriers = { "RAIL" },

		pillarBase =   { path.."pillar_btm.mdl"},
		pillarRepeat = { path.."pillar_btm.mdl"},
		pillarTop =    { path.."pillar_top.mdl"},

		railingBegin =  { path.."railing_rep_side.mdl",   path.."railing_rep_rep.mdl" },
		railingRepeat = { path.."railing_rep_side.mdl",   path.."railing_rep_rep.mdl" },
		railingEnd =    { path.."railing_rep_side.mdl",   path.."railing_rep_rep.mdl" },

		cost = 540.0,
	}
end
