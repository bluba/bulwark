// variable to prevent players rejoining during a wave
// EDITED BY: SMITH
playersInWave = [];
publicVariable "playersInWave";
missionNamespace setVariable ["buildPhase", true, true];

attkWave = 0;
publicVariable "attkWave";

debugNotification = false;
allBonusesDebug = false;

["<t size = '.5'>Loading lists.<br/>Please wait...</t>", 0, 0, 10, 0] remoteExec ["BIS_fnc_dynamicText", 0];
_hLocation = [] execVM "locationLists.sqf";
_hLoot     = [] execVM "loot\lists.sqf";
_hHostiles = [] execVM "hostiles\lists.sqf";
waitUntil {
    scriptDone _hLocation &&
    scriptDone _hLoot &&
    scriptDone _hHostiles
};
_hConfig   = [] execVM "editMe.sqf";
waitUntil { scriptDone _hConfig };
private _missing = [];
if (!isClass (configFile >> "CfgVehicles" >> "PSZ_PL_WDL10_Star_1466")) then {_missing pushBack "PSZ Bulwark truck"};
{
    if ((_x select {isClass (configFile >> "CfgVehicles" >> _x)}) isEqualTo []) then {
        _missing pushBack format ["enemy infantry tier %1", _forEachIndex + 1];
    };
} forEach [HOSTILE_LEVEL_1, HOSTILE_LEVEL_2, HOSTILE_LEVEL_3];
if !(_missing isEqualTo []) exitWith {
    private _message = format ["Bulwark: required mod content is missing: %1. Check PSZ, CUP and RHS.", _missing joinString ", "];
    diag_log _message;
    [_message] remoteExecCall ["hint", 0];
    "End1" call BIS_fnc_endMissionServer;
};

["<t size = '.5'>Creating Base...</t>", 0, 0, 30, 0] remoteExec ["BIS_fnc_dynamicText", 0];
_basepoint = [] execVM "bulwark\createBase.sqf";
waitUntil { scriptDone _basepoint };

["<t size = '.5'>Ready</t>", 0, 0, 0.5, 0] remoteExec ["BIS_fnc_dynamicText", 0];

OVERCASTVAR = 0.5;

ALLYTEAM = createGroup west;
publicVariable "ALLYTEAM";

publicVariable "bulwarkBox";
publicVariable "PARATROOP_CLASS";
publicVariable "BULWARK_SUPPORTITEMS";
publicVariable "BULWARK_SUPPLYITEMS";
publicVariable "BW_SUPPLY_CLASS";
publicVariable "BW_ENGINEERING_CLASS";
publicVariable "BW_DRONE_SUPPLY_CLASS";
publicVariable "BULWARK_BUILDITEMS";
publicVariable "PLAYER_STARTWEAPON";
publicVariable "PLAYER_STARTMAP";
publicVariable "PLAYER_STARTNVG";
publicVariable "PISTOL_HOSTILES";
publicVariable "DOWN_TIME";
publicVariable "ADDITIONAL_DOWN_TIME";
publicVariable "RESPAWN_TICKETS";
publicVariable "RESPAWN_TIME";
publicVariable "PLAYER_OBJECT_LIST";
publicVariable "MIND_CONTROLLED_AI";
publicVariable "SCORE_RANDOMBOX";
publicVariable "OVERCASTVAR";



//*Don't know if this was a good idea or not, but hey... it works!!! LOL  SMITH...*/
publicVariable "MAX_POINT_BANK_DEPOSIT_AMOUNT";
publicVariable "MAX_POINT_BANK_WITHDRAW_AMOUNT";

//determine if Support Menu is available
_supportParam = ("SUPPORT_MENU" call BIS_fnc_getParamValue);
if (_supportParam == 1) then {
  SUPPORTMENU = false;
}else{
  SUPPORTMENU = true;
};
publicVariable 'SUPPORTMENU';

//Determine team damage Settings
_teamDamageParam = ("TEAM_DAMAGE" call BIS_fnc_getParamValue);
if (_teamDamageParam == 0) then {
  TEAM_DAMAGE = false;
}else{
  TEAM_DAMAGE = true;
};
publicVariable 'TEAM_DAMAGE';

//determine if hitmarkers appear on HUD
HITMARKERPARAM = ("HUD_POINT_HITMARKERS" call BIS_fnc_getParamValue);
publicVariable 'HITMARKERPARAM';

_dayTimeHours = DAY_TIME_TO - DAY_TIME_FROM;
_randTime = floor random _dayTimeHours;
_timeToSet = DAY_TIME_FROM + _randTime;
setDate [2018, 7, 1, _timeToSet, 0];


EAST setFriend [WEST, 0];
WEST setFriend [EAST, 0];
WEST setFriend [RESISTANCE, 0];
RESISTANCE setFriend [WEST, 0];
EAST setFriend [RESISTANCE, 0];
RESISTANCE setFriend [EAST, 0];


//[] execVM "";
/*[] spawn {
  while {true} do {
    [] execVM "hostiles\airStrike.sqf";
    sleep 20;
  };
};*/
[bulwarkRoomPos] execVM "missionLoop.sqf";

//[] execVM "area\areaEnforcement.sqf";

[] execVM "hostiles\clearStuck.sqf";
[] execVM "extract.sqf";
//[] execVM "checkBulwark.sqf";
//[] execVM "hostiles\solidObjects.sqf";
[] spawn {
  while {true} do {
    [] execVM "hostiles\moveHosToPlayer.sqf";
    sleep 5;
  };
}; 
[] spawn {
  while {true} do {
    [] execVM "revivePlayers.sqf";
    sleep 5;
  };
} ;

[] spawn {
  while {true} do {
    [] execVM "supports\cleanup.sqf";
    sleep 10;
  };
}; 
