// Same finite stock as the former FPV Drone Supply Drop. No drone is deployed here.
private _stock = [
    ["magazine","UA_Item_EMPTY",1],
    ["magazine","UA_Item_NET",2],
    ["magazine","UA_Item_RPG18",2],
    ["magazine","UA_Item_AKS74",2],
    ["magazine","UA_Item_PG7VL_AT",2],
    ["magazine","UA_Item_OG7V_AP",1],
    ["magazine","UA_Item_TBG7L_HE",1],
    ["magazine","UA_Item_IED_AP",1],
    ["magazine","UA_Item_FIBER",1],
    ["magazine","UA_Item_FIBER_AT",2],
    ["magazine","UA_Item_BATTERY",30],
    ["magazine","UA_Item_PAYLOAD_PG7VL",6],
    ["magazine","UA_Item_PAYLOAD_IED",6],
    ["magazine","UA_Item_PAYLOAD_OG7V",6],
    ["magazine","UA_Item_PAYLOAD_TBG7L",6],
    ["magazine","UA_Item_PAYLOAD_NET",10],
    ["magazine","UA_Item_RPG18_TUBE",10],
    ["magazine","UA_Item_FIBER_SPOOL_15KM",6],
    ["magazine","UA_Item_FIBER_SPOOL_20KM",6],
    ["magazine","30Rnd_545x39_Mag_F",20],
    ["item","B_UavTerminal",4],
    ["item","ToolKit",2],
    ["backpack","B_Carryall_mcamo",4]
];
private _valid = true;
{
    _x params ["_tag","_class","_count"];
    private _root = switch (_tag) do {case "item": {"CfgWeapons"}; case "backpack": {"CfgVehicles"}; default {"CfgMagazines"}};
    if (!isClass (configFile >> _root >> _class)) exitWith {_valid = false};
} forEach _stock;
// Fail without payment if the required FPV mod/content is absent; never sell a partial kit.
if (!_valid) exitWith {[]};
_stock
