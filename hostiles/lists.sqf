/**
*  hostiles/lists
*
*  Populates global arrays with various unit types
*
*  Domain: Server
**/

_zombieSpider = [];
_zombiePlayer = [];
_zombieCrawler = [];
_zombieFast = [];
_zombieMedium = [];
_zombieSlow = [];
_zombieBoss = [];
_zombieWalker = [];

_count =  count (configFile >> "CfgVehicles");
for "_x" from 0 to (_count-1) do {
    _item=((configFile >> "CfgVehicles") select _x);
    if (isClass _item) then {
        if (getnumber (_item >> "scope") == 2) then {
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesspider") then {
                _zombieSpider = _zombieSpider + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesplayer") then {
                _zombiePlayer = _zombiePlayer + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "RyanzombiesCrawler") then {
                _zombieCrawler = _zombieCrawler + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesfast") then {
                _zombieFast = _zombieFast + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesslow") then {
                _zombieSlow = _zombieSlow + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesmedium") then {
                _zombieMedium = _zombieMedium + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombiesboss") then {
                _zombieBoss = _zombieBoss + [configname _item]
            };
            if (gettext (_item >> "vehicleClass") == "Ryanzombieswalker") then {
                _zombieWalker = _zombieWalker + [configname _item]
            };
        };
    };
};

List_ZombieSpider = _zombieSpider;
List_ZombiePlayer = _zombiePlayer;
List_ZombieCrawler = _zombieCrawler;
List_ZombieFast = _zombieFast;
List_ZombieMedium = _zombieMedium;
List_ZombieSlow = _zombieSlow;
List_ZombieBoss = _zombieBoss;
List_ZombieWalker = _zombieWalker;


_bandits = [];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "BanditCombatGroup";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _bandits)==false) then 
      {
		    _bandits pushback getText (_item >> "vehicle");
      };
    };
};
List_Bandits = _bandits;
diag_log ["List_Bandits %0", List_Bandits];

_paraBandits = [];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaCombatGroup";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _paraBandits)==false) then 
      {
		    _paraBandits pushback getText (_item >> "vehicle");
      };
    };
};
List_ParaBandits = _paraBandits;
diag_log ["List_ParaBandits %0", List_ParaBandits];

_eastSoldier = [];
_groupConfig = configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad";_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _eastSoldier)==false) then 
      {
		    _eastSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_OPFOR %0", _eastSoldier];
_groupConfig = configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AT";_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _eastSoldier)==false) then 
      {
		    _eastSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_OPFOR %0", _eastSoldier];
_groupConfig = configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AA";_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _eastSoldier)==false) then 
      {
		    _eastSoldier pushback getText (_item >> "vehicle");
      };
    };
};

List_OPFOR = _eastSoldier;
diag_log ["List_OPFOR %0", List_OPFOR];

_indSoldier = [];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _indSoldier)==false) then 
      {
		    _indSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_INDEP %0", _indSoldier];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad_Weapons";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _indSoldier)==false) then 
      {
		    _indSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_INDEP %0", _indSoldier];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AT";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _indSoldier)==false) then 
      {
		    _indSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_INDEP %0", _indSoldier];
_groupConfig = configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AA";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _indSoldier)==false) then 
      {
		    _indSoldier pushback getText (_item >> "vehicle");
      };
    };
};

List_INDEP = _indSoldier;
diag_log ["List_INDEP %0", List_INDEP];

_natoSoldier = [];
_groupConfig = configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfSquad";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
     if((getText (_item >> "vehicle") in _natoSoldier)==false) then 
      {
		    _natoSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_NATO %0", _natoSoldier];
_groupConfig = configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfSquad_Weapons";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
     if((getText (_item >> "vehicle") in _natoSoldier)==false) then 
      {
		    _natoSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_NATO %0", _natoSoldier];
_groupConfig = configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfTeam_AT";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
     if((getText (_item >> "vehicle") in _natoSoldier)==false) then 
      {
		    _natoSoldier pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_NATO %0", _natoSoldier];
_groupConfig = configfile >> "CfgGroups" >> "West" >> "BLU_F" >> "Infantry" >> "BUS_InfAssault";
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=(_groupConfig select _x);
    if (isClass _item) then {
     if((getText (_item >> "vehicle") in _natoSoldier)==false) then 
      {
		    _natoSoldier pushback getText (_item >> "vehicle");
      };
    };
};

List_NATO = _natoSoldier;

diag_log ["List_NATO %0", List_NATO];

_viper = [];
_groupConfig = configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "SpecOps" >> "OI_ViperTeam";
_count =  count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _viper)==false) then 
      {
		    _viper pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_Viper %0", _viper];
_groupConfig = configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "O_InfTeam_AT_Heavy";
_count =  count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _viper)==false) then 
      {
		    _viper pushback getText (_item >> "vehicle");
      };
    };
};
diag_log ["List_Viper %0", _viper];
_groupConfig = configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfAssault";
_count =  count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _viper)==false) then 
      {
		    _viper pushback getText (_item >> "vehicle");
      };
    };
};

List_Viper = _viper;
diag_log ["List_Viper %0", List_Viper];

_armouredVehicles = [];
_cfgVehicles = configFile >> "CfgVehicles";
_entries = count _cfgVehicles;
_realentries = _entries - 1;
for "_x" from 0 to (_realentries) do {
  _checked_veh = _cfgVehicles select _x;
  _classname = configName _checked_veh;
  if (isClass _checked_veh) then { // CHECK IF THE SELECTED ENTRY IS A CLASS
    _vehclass = getText (_checked_veh >> "vehicleClass");
    _scope = getNumber (_checked_veh >> "scope");
    _simulation_paracheck = getText (_checked_veh >> "simulation");
    _actual_vehclass = getText (_checked_veh >> "vehicleClass");
    if (_vehclass == _vehClass && _scope != 0 && _simulation_paracheck != "parachute" && _classname != "O_MBT_02_arty_F" && _actual_vehclass == "Armored") exitWith {
      _armouredVehicles pushback _classname;
    };
  };
};
List_Armour = _armouredVehicles;


_armedCars = [];
_cfgVehicles = configFile >> "CfgVehicles";
_entries = count _cfgVehicles;
_realentries = _entries - 1;
for "_x" from 0 to (_realentries) do {
  _checked_veh = _cfgVehicles select _x;
  _classname = configName _checked_veh;
  if (isClass _checked_veh) then {
    _vehclass = getText (_checked_veh >> "vehicleClass");
    _scope = getNumber (_checked_veh >> "scope");
    _simulation_paracheck = getText (_checked_veh >> "simulation");
    _actual_vehclass = getText (_checked_veh >> "vehicleClass");
    turretWeap = false;
    if (isClass (_checked_veh >> "Turrets")) then {
      _vechTurrets = _checked_veh >> "Turrets";
      for "_turretIter" from 0 to (count _vechTurrets - 1) do {
        _weapsOnTurret = _vechTurrets select _turretIter;
        if (!(getarray (_weapsOnTurret >> "weapons") isEqualTo [])) then {
          turretWeap = true;
        };
      };
    };
    if (_vehclass == _vehClass && _scope != 0 && _actual_vehclass == "Car" && turretWeap) exitWith {
      _armedCars pushback _classname;
    };
  };
};
List_ArmedCars = _armedCars;


_armedHelis = [];
_armedHelis pushback "PSZ_PL_Mi17_1W";
_armedHelis pushback "PSZ_PL20_Mi17_1W_UB32";
_armedHelis pushback "PSZ_PL20_Mi17_1W_PKT";
_armedHelis pushback "PSZ_Mi24D";
_armedHelis pushback "PSZ_Mi24V";
_armedHelis pushback "CUP_O_Ka52_GreyCamo_RU";
_armedHelis pushback "B_Heli_Light_01_armed_F";
_armedHelis pushback "CUP_O_Ka50_DL_SLA";
_armedHelis pushback "CUP_I_UH1H_armed_TK_GUE";
_armedHelis pushback "CUP_I_UH1H_slick_TK_GUE";
_armedHelis pushback "RHS_Ka52_base";
_armedHelis pushback "rhs_ka60_grey";
_armedHelis pushback "rhsgref_mi24g_CAS";
_armedHelis pushback "rhsgref_mi24g_UPK23";
_armedHelis pushback "rhsgref_mi24g_FAB";
_armedHelis pushback "rhs_mi28_base";
_armedHelis pushback "rhs_uh1h_hidf_gunship";
List_Helis = _armedHelis;

List_RUSSIA_LVL_1 = ["CUP_O_RU_Soldier_SL",
"CUP_O_RU_Soldier_Saiga",
"CUP_O_RU_Soldier",
"CUP_O_RU_Soldier_Medic_MSV_VSR93"];

List_RUSSIA_LVL_2 = ["CUP_O_RU_Soldier_AA",
"CUP_O_RU_Soldier_TL_MSV_VSR93",
"CUP_O_RU_Soldier_AAR_MSV_VSR93",
"CUP_O_RU_Soldier_EXP_MSV_VSR93",
"CUP_O_RU_Soldier_MG_MSV_VSR93",
"CUP_O_RU_Soldier_Medic_MSV_VSR93",
"CUP_O_RU_Soldier_Lite_MSV_VSR93",
"CUP_O_RU_Soldier_AT_MSV_VSR93",
"CUP_O_RU_Soldier_SL_MSV_VSR93",
"CUP_O_RU_Soldier_GL_MSV_VSR93"];

List_RUSSIA_LVL_3 = ["O_R_recon_medic_F",
"O_R_recon_JTAC_F",
"O_R_recon_M_F",
"O_R_recon_LAT_F",
"O_R_recon_GL_F",
"O_R_recon_AR_F",
"CUP_O_RU_Soldier_SL_Ratnik_Summer",
"CUP_O_RU_Soldier_TL_Ratnik_Summer",
"CUP_O_RU_Soldier_GL_Ratnik_Summer",
"CUP_O_RU_Soldier_MG_Ratnik_Summer",
"CUP_O_RU_Soldier_AHAT_Ratnik_Summer",
"CUP_O_RU_Sniper_VDV",
"CUP_O_RU_Sniper_KSVK_VDV",
"CUP_O_RU_Soldier_LAT_Ratnik_Summer",
"CUP_O_RU_Soldier_AA_Ratnik_Summer",
"CUP_O_RUS_Soldier_Marksman",
"CUP_O_RUS_Soldier_GL",
"CUP_O_RU_Soldier_Ratnik_Summer",
"CUP_O_RU_Soldier_Medic_Ratnik_Summer"];

List_RUSSIA_CARS = ["CUP_O_UAZ_METIS_RU",
"CUP_O_UAZ_MG_RU",
"CUP_O_GAZ_Vodnik_KPVT_RU",
"CUP_O_GAZ_Vodnik_BPPU_RU",
"CUP_O_GAZ_Vodnik_PK_RU",
"CUP_O_GAZ_Vodnik_AGS_RU",
"CUP_O_UAZ_AA_RU",
"CUP_O_URAL_ZU23_RU",
"RHS_Ural_Open_MSV_01",
"rhs_tigr_m_3camo_msv",
"rhsgref_BRDM2_msv",
"rhs_2b14_82mm_msv",
"CUP_0_UAZ_Open_RU",
"CUP_0_UAZ_SPG9_RU",
"rhs_pts_vmf",
"rhs_gaz66_zu23_vmf",
"rhsgref_BRDM2_umf",
"rhs_tigr_sts_umv"];

List_RUSSIA_ARMOR = ["CUP_O_T72_RU",
"CUP_O_T90_RU",
"CUP_O_BMP2_RU",
"CUP_O_BMP3_RU",
"CUP_O_BRDM2_RU",
"CUP_O_BTR80_CAMO_RU",
"CUP_O_BTR90_RU",
"CUP_O_2S6M_RU",
"rhs_D30_vmf",
"rhs_btr80a_msv",
"CUP_0_BTR80_GREEN_RU",
"rhs_2s3_at_tv",
"rhs_2s1_at_tv",
"rhs_t14_tv",
"rhs_t15_tv",
"rhs_t80um",
"rhs_t90sm_tv",
"rhs_bmd4_vdv",
"rhs_sprut_vdv"];

LIST_RUSSIA_HELI = ["CUP_O_Mi8_RU",
"CUP_O_RU_Mi24_V_Dynamic_RU",
"CUP_O_Ka60_Grey_RU",
"CUP_O_Ka52_RU",
"CUP_O_Ka50_DL_RU",
"rhs_mi28n_vvsc"];

List_SUICIDE_RUSSIA = ["CUP_O_RU_Survivor_MSV_VSR93"];

List_DEFECTOR_CARS = [
  "B_MRAP_01_gmg_F",
  "B_MRAP_01_hmg_F",
  "CUP_B_nM1025_M240_NATO",
  "B_LSV_01_armed_F"
];

List_DEFECTOR_ARMOR = [
  "CUP_B_M1A2SEP_NATO",
  "B_APC_Wheeled_01_cannon_F",
  "B_APC_Tracked_01_rcws_F",
  "B_MBT_01_TUSK_F",
  "CUP_B_Challenger2_NATO"
];

List_DEFECTOR_HELI = [
  "B_Heli_Transport_01_F",
  "B_Heli_Transport_03_F",
  "B_Heli_Light_01_dynamicLoadout_F"
];

List_DEFECTOR_INF = [
  "B_recon_TL_F",
  "B_recon_medic_F",
  "B_recon_JTAC_F",
  "B_recon_M_F",
  "B_sniper_F",
  "B_Patrol_Soldier_TL_F",
  "B_Patrol_Soldier_AR_F",
  "B_recon_Sharpshooter_F",
  "B_Patrol_Medic_F"
];