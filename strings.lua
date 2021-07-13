local desc_en = [[This mod is the Tpf2 adapatation of the same mod from Tpf1, only bridges and track selection is improved since.

Features:
* From 2 to 12 tracks
* From 40m to 480m platform lengths
* Santiago Calatrava style roof inspired by Reggio Emilia AV Mediopadana Station, or simple roofs
* Customizable roofs
* Available from 1990

]]

local desc_fr = [[Ce mod est l'adaptation du mod de même nom dans Tpf1, il y a qu'amélioration sur le pont et la sélection de type de voie 

Caractéristiques:
* Longueur de platformes de 40m jusqu'à 480m
* De 2 jusqu'à 12 voies
* Plafond du style de Santiago Calatrava inspiré par la gare de Reggio Emilia AV Mediopadana
* Plafond personalisable
* Disponible depuis 1990
]]

local desc_zh = [[此模组为一代中同名模组的二代版本，改进了内置桥梁以及轨道类型的选择

特点：
* 站台长度从40米到480米
* 二至十二条股道
* 受 Reggio Emilia AV Mediopadana 车站启发的 Santiago Calatrava 风格顶棚 
* 可定制的顶棚
* 1990年起可用
]]

local desc_ts = [[此模組為一代中同名模組的二代版本，改進了內置橋樑以及軌道類型的選擇

特點：
* 月臺長度從40米到480米
* 二至十二條股道
* 受 Reggio Emilia AV Mediopadana 車站啟發的 Santiago Calatrava 風格頂棚 
* 可定制的頂棚
* 1990年起可用
]]

function data()
    return {
        en = {
            MOD_NAME = "Elevated station",
            MOD_DESC = desc_en,
            MENU_NAME = "Elevated Train Station",
            MENU_DESC = "An elevated train station",
            MENU_NR_TRACKS = "Number of tracks",
            MENU_LAYOUT = "Track Layout",
            MENU_PLATFORM_LENGTH = "Platform length",
            MENU_HEIGHT = "Station height",
            MENU_ROOF_LENGTH = "Roof length",
            MENU_ROOF_DENSITY = "Roof frame Density",
            MENU_TRAM = "Tram track",
            MENU_NO_ROOF = "No roof",
            MENU_DENSE_LESS = "Less dense",
            MENU_DENSE_NORMAL = "Normal",
            MENU_DENSE_SIMPLE = "Simple",
            MENU_TRACK_TYPE = "Track Type",
            MENU_CATENARY = "Catenary",
            MENU_FULL_ROOF = "Full roof"
        },
        fr = {
            MOD_NAME = "Gare surélévée",
            MOD_DESC = desc_fr,
            MENU_NAME = "Gare surélévée",
            MENU_DESC = "Une gare surélévée",
            MENU_NR_TRACKS = "Nombre de voies",
            MENU_LAYOUT = "Disposition de voie",
            MENU_PLATFORM_LENGTH = "Longeur de plateforms",
            MENU_HEIGHT = "Hauteur de la gare",
            MENU_ROOF_LENGTH = "Longeur de plafond",
            MENU_ROOF_DENSITY = "Style de plafond",
            MENU_TRAM = "Voie de tram",
            MENU_NO_ROOF = "Sans",
            MENU_DENSE_LESS = "Moins dense",
            MENU_DENSE_NORMAL = "Normale",
            MENU_DENSE_SIMPLE = "Simple",
            MENU_TRACK_TYPE = "Type de voie",
            MENU_CATENARY = "Caténaire",
            MENU_FULL_ROOF = "Complet"
        },
        zh_CN = {
            MOD_NAME = "高架车站",
            MOD_DESC = desc_zh,
            MENU_NAME = "高架车站",
            MENU_DESC = "一座高架车站",
            MENU_NR_TRACKS = "轨道数量",
            MENU_LAYOUT = "轨道布局",
            MENU_PLATFORM_LENGTH = "站台长度(米)",
            MENU_HEIGHT = "车站高度(米)",
            MENU_ROOF_LENGTH = "顶棚长度",
            MENU_ROOF_DENSITY = "顶棚密度",
            MENU_TRAM = "有轨电车轨道",
            MENU_NO_ROOF = "无",
            MENU_DENSE_LESS = "疏",
            MENU_DENSE_NORMAL = "标准",
            MENU_DENSE_SIMPLE = "普通",
            MENU_TRACK_TYPE = "轨道类型",
            MENU_CATENARY = "接触网",
            MENU_FULL_ROOF = "全长"
        },
        zh_TW = {
            MOD_NAME = "高架車站",
            MOD_DESC = desc_zh,
            MENU_NAME = "高架車站",
            MENU_DESC = "一座高架車站",
            MENU_NR_TRACKS = "軌道數量",
            MENU_LAYOUT = "軌道佈局",
            MENU_PLATFORM_LENGTH = "月臺長度(公尺)",
            MENU_HEIGHT = "車站高度(公尺)",
            MENU_ROOF_LENGTH = "頂棚長度",
            MENU_ROOF_DENSITY = "頂棚密度",
            MENU_TRAM = "有軌電車軌道",
            MENU_NO_ROOF = "無",
            MENU_DENSE_LESS = "疏",
            MENU_DENSE_NORMAL = "標準",
            MENU_DENSE_SIMPLE = "普通",
            MENU_TRACK_TYPE = "軌道類型",
            MENU_CATENARY = "接觸網",
            MENU_FULL_ROOF = "全長"
        },
    }
end
