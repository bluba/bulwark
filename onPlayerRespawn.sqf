// Protect the new body while initialization/searching would leave it at the old spawn.
private _respawnUnit = player;
private _restoreDamage = isDamageAllowed _respawnUnit;
_respawnUnit allowDamage false;
private _droneSession = missionNamespace getVariable ["BW_droneControlSession", []];
if !(_droneSession isEqualTo []) then {[_droneSession select 0] call supports_fnc_endDroneControl};
waitUntil {!isNil "bulwarkBox"};
["Terminate"] call BIS_fnc_EGSpectator;
player setVariable ["buildItemHeld", false, true];
player setVariable ["RevByMedikit", false, true];
player setVariable ["bw_respawnReserved", false, true];

//Make player immune to fall damage and immune to all damage while incapacitated
waitUntil {!isNil "TEAM_DAMAGE"};
player removeAllEventHandlers "HandleDamage";
player addEventHandler ["HandleDamage", {_this call bulwark_fnc_handleDamage}];

//delete empty continers
[player, ['Take', {
  params ['_unit', '_container', '_item'];
  [_container] remoteExecCall ["loot_fnc_deleteIfEmpty", 2];
}]] remoteExec ['addEventHandler', 0, true];

//remove and add gear
removeHeadgear player;
removeGoggles player;
removeVest player;
removeBackpack player;
removeAllWeapons player;
removeAllAssignedItems player;
private _respawnPosition = [];
waitUntil {
    _respawnPosition = [bulwarkBox, _respawnUnit] call bulwark_fnc_findPlaceAround;
    if (_respawnPosition isEqualTo []) then {sleep 1};
    !(_respawnPosition isEqualTo []) || {player != _respawnUnit} || {!alive _respawnUnit}
};
if (player != _respawnUnit || {!alive _respawnUnit}) exitWith {_respawnUnit allowDamage _restoreDamage};
_respawnUnit setVelocity [0, 0, 0];
_respawnUnit setPosASL _respawnPosition;
_respawnUnit allowDamage _restoreDamage;

if(PLAYER_STARTWEAPON) then {
    player addMagazine "16Rnd_9x21_Mag";
    player addMagazine "16Rnd_9x21_Mag";
    player addWeapon "hgun_P07_F";
};

if(PLAYER_STARTMAP) then {
    player addItem "ItemMap";
    player assignItem "ItemMap";
    player linkItem "ItemMap";
};

if(PLAYER_STARTNVG) then {
    player addItem "Integrated_NVG_F";
    player assignItem "Integrated_NVG_F";
    player linkItem "Integrated_NVG_F";
};

if (isClass (configfile >> "CfgVehicles" >> "tf_anarc164")) then {
  player addItem "tf_anprc152";
};

waituntil {alive player};

//Disarm mines and explosives
_disarm =
{
    _explosive = nearestObject [player, "TimeBombCore"];
	deleteVehicle _explosive;
    _explosiveClass = typeOf _explosive;
    _count =  count (configFile >> "CfgMagazines");
    for "_x" from 0 to (_count-1) do {
        _item=((configFile >> "CfgMagazines") select _x);
		if (getText (_item >> "ammo") isEqualTo _explosiveClass) then {
			player addMagazine configName _item;
		};
    };
	player playAction "PutDown";
};
player addAction ["Disarm Explosive",_disarm,nil,2,false,true,"","(player distance2D nearestObject [player, 'TimeBombCore']) <= 1.6"];
_disarmMine =
{
    _explosive = nearestObject [player, "mineBase"];
	deleteVehicle _explosive;
    player playAction "PutDown";
};
player addAction ["Disarm Mine",_disarmMine,nil,2,false,true,"","(player distance2D nearestObject [player, 'mineBase']) <= 1.6"];

[] remoteExec ["killPoints_fnc_updateHud", 0];
