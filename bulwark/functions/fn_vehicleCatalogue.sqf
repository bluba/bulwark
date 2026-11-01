// [class, ticket cost including cargo, reserved (0; no model unlocks), role, cargo count]
private _ru = [
 ["CUP_O_UAZ_MG_RU",2,0,"patrol",0], ["CUP_O_GAZ_Vodnik_PK_RU",3,0,"patrol",0],
 ["rhsgref_BRDM2_msv",4,0,"patrol",0], ["CUP_O_UAZ_METIS_RU",6,0,"support",0],
 ["CUP_O_GAZ_Vodnik_AGS_RU",6,0,"support",0], ["CUP_O_GAZ_Vodnik_KPVT_RU",6,0,"armour",0],
 ["CUP_O_GAZ_Vodnik_BPPU_RU",8,0,"armour",0], ["CUP_O_URAL_ZU23_RU",8,0,"support",0],
 ["RHS_Ural_Open_MSV_01",3,0,"truck",5], ["RHS_Ural_Open_MSV_01",5,0,"truck",10],
 ["RHS_Mi8mt_Cargo_vvsc",7,0,"transportAir",5], ["CUP_O_BTR80_CAMO_RU",6,0,"armour",0],
 ["rhs_btr80a_msv",8,0,"armour",0], ["CUP_O_BMP2_RU",8,0,"armour",0],
 ["CUP_O_BMP3_RU",9,0,"armour",0], ["CUP_O_T72_RU",10,0,"heavy",0],
 ["CUP_O_T90_RU",13,0,"heavy",0], ["rhs_t14_tv",15,0,"heavy",0],
 ["rhs_t15_tv",12,0,"heavy",0], ["rhs_t80um",12,0,"heavy",0],
 ["rhs_t90sm_tv",14,0,"heavy",0], ["rhs_bmd4_vdv",8,0,"armour",0],
 ["rhs_sprut_vdv",10,0,"heavy",0], ["CUP_O_Ka52_RU",15,0,"combatAir",0],
 ["CUP_O_Ka50_DL_RU",13,0,"combatAir",0], ["CUP_O_RU_Mi24_V_Dynamic_RU",12,0,"combatAir",0],
 ["rhs_mi28n_vvsc",15,0,"combatAir",0]
];
private _west = [
 ["B_LSV_01_armed_F",2,0,"patrol",0], ["CUP_B_nM1025_M240_NATO",2,0,"patrol",0],
 ["B_MRAP_01_hmg_F",3,0,"patrol",0], ["B_MRAP_01_gmg_F",6,0,"support",0],
 ["B_Truck_01_transport_F",3,0,"truck",5], ["B_Heli_Transport_01_F",8,0,"transportAir",5],
 ["B_APC_Tracked_01_rcws_F",7,0,"armour",0], ["B_APC_Wheeled_01_cannon_F",8,0,"armour",0],
 ["CUP_B_M1A2SEP_NATO",14,0,"heavy",0], ["B_MBT_01_TUSK_F",14,0,"heavy",0],
 ["CUP_B_Challenger2_NATO",14,0,"heavy",0], ["B_Heli_Light_01_dynamicLoadout_F",10,0,"combatAir",0]
];
private _legacy = [
 ["O_G_Offroad_01_armed_F",2,0,"patrol",0], ["O_MRAP_02_hmg_F",3,0,"patrol",0],
 ["O_MRAP_02_gmg_F",6,0,"support",0], ["O_Truck_03_transport_F",3,0,"truck",5],
 ["O_Heli_Light_02_unarmed_F",6,0,"transportAir",5], ["O_APC_Wheeled_02_rcws_v2_F",8,0,"armour",0],
 ["O_APC_Tracked_02_cannon_F",8,0,"armour",0], ["O_MBT_02_cannon_F",10,0,"heavy",0],
 ["O_Heli_Attack_02_dynamicLoadout_F",14,0,"combatAir",0]
];
private _pool = if (defectorWave) then {_west} else {if (OPFORMODE == 2) then {_ru} else {_legacy}};
_pool select {private _cfg = configFile >> "CfgVehicles" >> (_x select 0); isClass _cfg && {getNumber (_cfg >> "scope") == 2} && {getNumber (_cfg >> "transportSoldier") >= (_x select 4)}}
