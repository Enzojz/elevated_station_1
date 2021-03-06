local desc_en = [[An elevated station minimizing the use of terrain.
Features:
* From 2 to 12 tracks
* From 40m to 480m platform lengths
* Santiago Calatrava style roof inspired by Reggio Emilia AV Mediopadana Station, or simple roofs
* Customizable roofs
* Available from 1990

To be implemented:
* Extra street connection
* Central tracks without platforms
* 1920 era station
* As suggestion from players

---------------
Changelog
1.8
- Changed option "Always tracks in the middle" to "Track Layout"
1.7
- Correction of crash with central platform with 2 tracks layout.
- Correction of option "Always tracks in the middle"
1.6
- Correction of the distortion of trams running through under the entry
1.5
- Added the option to have central tracks or not
1.4
- Central tracks for 2, 6, 10 tracks configurations
1.3
- Fixed bug that door opens always on right side
1.2
- Fixed 320m station street connection bug
- Fixed failure on large road connection from the back side of the station
1.1
- Bugfix and improvements to materials
1.0
- First release
--------------- 
* Planned projects 
- Curved station 
- Overground / elevated Crossing station
- Overground / underground Crossing station
- Lyon St Exupery

]]

local desc_fr = [[Une gare surélévé qui economise l'utlisation de terrain au maximum.
Caractéristiques:
* Longueur de platformes de 40m jusqu'à 480m
* De 2 jusqu'à 12 voies
* Plafond du style de Santiago Calatrava inspiré par la gare de Reggio Emilia AV Mediopadana
* Plafond personalisable
* Disponible depuis 1990

À implémenter
* Connection de rue supplémentaire
* Voie centrales sans platformes

---------------
Changelog
1.8
- Changement "Toujours voie en centre" vers "Disposition de voie"
1.7
- Correction de plantage avec plateforme centrale en 2 voies.
- Correction d'option "Toujours voie en centre"
1.6
- Correction de déformation des trams lors son passage sous l'entrée
1.5
- Ajoute d'option pour voies centrale
1.4
- Voies centrales pour les configuration de 2, 6, 10 voies
1.3
- Correction de bug d'ouverture de porte qu'à côté droite
1.2
- Correction du bug de connexion routière sur la gare de 320m
- Correction du bug d'échec de connexion routière de côté arrière de la gare
1.1
- Correction et amélioration des matériaux
1.0
- Première version
--------------- 
* Projets planifé 
- Gare en courbe 
- Gare en croix (souterrain + surface, surface + surélevé)
- Lyon St Exupery

]]
local desc_zh = [[一种非常节约用地的高架车站
特点：
* 站台长度从40米到480米
* 二至十二条股道
* 受 Reggio Emilia AV Mediopadana 车站启发的 Santiago Calatrava 风格顶棚 
* 可定制的顶棚
* 1990年起可用

待实现：
* 额外的出口
* 2、6、10股道配置下的侧岛式车站配置
* 无站台正线

---------------
Changelog
1.8
- 将“中央轨道”选项改为了“轨道布局”
1.7
- 修正了两股道中央站台时的退出错误
- 修正了“中央股道”的错误
1.6
- 修正了有轨电车从入口下通过时的渲染错误
1.5
- 增加了中央轨道的选项
1.4
- 将2, 6, 10轨道布局改成了侧岛式站台
1.3
- 修正了只在右边开车门的错误
1.2
- 修正了320米车站无法进行道路连接的错误
- 修正了无法从车站背面连接最宽道路的错误
1.1
- 修正和改进了材质
1.0
- 首次发布
]]

function data()
    return {
        en = {
            ["name"] = "Elevated station",
            ["desc"] = desc_en
        },
        fr = {
            ["name"] = "Gare surélévée",
            ["desc"] = desc_fr,
            ["Elevated Train Station"] = "Gare surélévée",
            ["An elevated train station"] = "Une gare surélévée",
            ["Number of tracks"] = "Nombre de voies",
            ["Track Layout"] = "Disposition de voie",
            ["Platform length"] = "Longeur de plateforms",
            ["Station height"] = "Hauteur de la gare",
            ["Roof length"] = "Longeur de plafond",
            ["Roof frame Density"] = "Style de plafond",
            ["Tram track"] = "Voie de tram",
            ["No roof"] = "Sans",
            ["Less dense"] = "Moins dense",
            ["Normal"] = "Normale",
        },
        zh_CN = {
            ["name"] = "高架车站",
            ["desc"] = desc_zh,
            ["Elevated Train Station"] = "高架车站",
            ["An elevated train station"] = "一座高架车站",
            ["Number of tracks"] = "轨道数量",
            ["Track Layout"] = "轨道布局",
            ["Platform length"] = "站台长度",
            ["Station height"] = "车站高度",
            ["Roof length"] = "顶棚长度",
            ["Roof frame Density"] = "顶棚密度",
            ["Tram track"] = "有轨电车轨道",
            ["No roof"] = "无",
            ["Simple"] = "普通",
            ["Less dense"] = "疏",
            ["Normal"] = "标准",
        },
    }
end
