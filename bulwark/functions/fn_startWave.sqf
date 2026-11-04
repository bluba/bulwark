/**
*  fn_startWave
*
*  starts a new Wave
*
*  Domain: Server
**/
if (!isServer) exitWith {};
diag_log "startWave";
private _debugForced = [attkWave + 1] call bulwark_fnc_debugForced;
private _debugSpecial = if (_debugForced) then {BW_DEBUG_FORCED_WAVE select 1} else {""};
if (!_debugForced) then {BW_DEBUG_FORCED_WAVE = []};

["Terminate"] remoteExec ["BIS_fnc_EGSpectator", 0];
[] remoteExec ["killPoints_fnc_updateHud", 0];

// First wave has its own warning; later waves consume the intermission deadline.
private _deadline = missionNamespace getVariable ["BW_PREP_DEADLINE", -1];
// If everybody left and the deadline expired, give returning players a warning.
if (_deadline < time) then {_deadline = time + 15};
if (_debugForced) then {_deadline = time};
BW_PREP_DEADLINE = -1;
while {time < _deadline && {!missionExtract} && {runMissionLoop} &&
    {(missionNamespace getVariable ["BW_DEBUG_NEXT_SPECIAL", ""]) == ""}} do {
    [] call bulwark_fnc_tacticalState;
    private _remaining = ceil (_deadline - time);
	if(_remaining <= 4) then {"beep_target" remoteExec ["playsound", 0];} else {"readoutClick" remoteExec ["playsound", 0];};
	[format ["<t>%1</t>", _remaining], 0, 0, 1, 0] remoteExec ["BIS_fnc_dynamicText", 0];
	sleep 1;
    if (missionExtract) exitWith {};
};
if (missionExtract || {!runMissionLoop} || {(missionNamespace getVariable ["BW_DEBUG_NEXT_SPECIAL", ""]) != ""}) exitWith {};


// Delete
[(missionNamespace getVariable ["BW_FPV_OPERATOR",createHashMap]) getOrDefault ["id",-1],"nextWave"] call bulwark_fnc_endFpv;
[(missionNamespace getVariable ["BW_OFFICER_HUNT", createHashMap]) getOrDefault ["id", -1], "nextWave"] call bulwark_fnc_endOfficerHunt;
_final = waveUnits select ("BODY_CLEANUP" call BIS_fnc_getParamValue);
{deleteVehicle _x} foreach _final;
// Shuffle
waveUnits set [2, waveUnits select 1];
waveUnits set [1, waveUnits select 0];
waveUnits set [0, []];

playersInWave = [];
_allHCs = entities "HeadlessClient_F";
_allHPs = allPlayers - _allHCs;
{ playersInWave pushBack getPlayerUID _x; } foreach _allHPs;
publicVariable "playersInWave";

attkWave = (attkWave + 1);
publicVariable "attkWave";

waveSpawned = false;

//If last wave was a night time wave then skip back to the time it was previously
if(!isNil "nightWave") then {
	if (nightWave) then {
		skipTime currentTime;
	};
};

60 setFog 0;
ovar = ((random 2)-1);
OVERCASTVAR = OVERCASTVAR + (ovar*0.2);
if(OVERCASTVAR>1) then {
	OVERCASTVAR =1;
};
if(OVERCASTVAR<0) then{
	OVERCASTVAR=0;
};
publicVariable "OVERCASTVAR";
[OVERCASTVAR] call BIS_fnc_setOvercast;
diag_log format [" overcast %1 %2", OVERCASTVAR, ovar]; 

[] remoteExec ["killPoints_fnc_updateHud", 0];

missionNamespace setVariable ["buildPhase", false, true];
[] call bulwark_fnc_tacticalState;
private _waveId = attkWave;
BW_ENEMY_LIMIT = 120 min (30 + 4 * count ([] call bulwark_fnc_humanPlayers));
BW_SPAWN_QUEUE = [];
BW_SPAWN_JOBS = [];
BW_SPAWN_SERIAL = 0;
call compile preprocessFileLineNumbers "hostiles\vehicleSettings.sqf";
BW_VEHICLE_TICKETS_ACTIVE = BW_VEHICLE_TICKETS;
BW_INFANTRY_REMAINING = 0;
[_waveId] execVM "bulwark\defendLocationBonus.sqf";

	dronesquad = [];
	defectorWave = false;
	demineWave = false;
	suicideWave = false;
	nightWave = false;
	fogWave = false;
	swticharooWave = false;
	specMortarWave = false;
	specCivs = false;
	droneCount = 0;

//paradrop is in both wave and modifier, mix of para+para is not bad and para + anything mixes well

	_beginerSpecials = ["specCivs","fogWave","thunderstorm"];
	_standardModifiers = ["fogWave","nightWave","thunderstorm","arty", "grad", "paraDrop","specMortarWave", "airstrike","convoy"];

	_all = ["specCivs","suicideWave","specMortarWave", "grad","demineWave","defectorWave","nightWave","fogWave","thunderstorm","arty", "paraDrop", "airstrike","encampment","convoy"];
	_additionalModsAfter15 = ["specMortarWave","paraDrop","convoy"];
	_nonModified = ["specCivs","suicideWave","specMortarWave","demineWave","defectorWave", "paraDrop", "airstrike","convoy","encampment","officerHunt","fpvOperator"];

	_wave = "";
	_modifier = "";
	_secondModifier = "";

	waveTypes= [];
    private _vehicleWave = "ARMOUR_START_WAVE" call BIS_fnc_getParamValue;
    private _vehicleSpecialsAllowed = _vehicleWave < 9999 && {attkWave >= _vehicleWave};
    // Filter before drawing: weather/time and FOBs are unique; other combat effects may stack.
    // A disabled vehicle special must not consume the replacement slot either.
    private _addSpecial = {
        params ["_pool"];
        private _eligible = _pool select {
            !(_x in ["fogWave", "nightWave", "thunderstorm"] && {_x in waveTypes}) &&
            {_x != "encampment" || {[_waveId, waveTypes] call bulwark_fnc_fobAvailable}} &&
            {_x != "officerHunt" || {[_waveId, waveTypes] call bulwark_fnc_officerHuntAvailable}} &&
            {_x != "fpvOperator" || {[_waveId, waveTypes] call bulwark_fnc_fpvAvailable}} &&
            {_vehicleSpecialsAllowed || {!(_x in ["convoy", "paraDrop", "airstrike", "specMortarWave", "demineWave"])}}
        };
        if !(_eligible isEqualTo []) then {waveTypes pushBack (selectRandom _eligible)};
    };
	
	_randomSpec = random 100;	
	_random1Mod = random 100;
	_random2Mod = random 100;
	_isSpecial = _randomSpec < 35+ attkWave;
	
	if(attkWave>16) then {
		[_additionalModsAfter15] call _addSpecial;
	};

	if(_isSpecial) then {
		if(attkWave > 4 and attkWave<7) then {
			[_beginerSpecials] call _addSpecial; 
		};
		if(attkWave > 6 && attkWave < 10) then {
			[_all] call _addSpecial; 
		};
		if( attkWave > 9 and attkWave < 14) then {
			[_nonModified] call _addSpecial; 
			if(_random1Mod < 50) then {
				[_standardModifiers] call _addSpecial; 
			};
		};
		if(attkWave > 13 and attkWave < 17) then {
			[_nonModified] call _addSpecial; 
			if(_random1Mod < 75) then {
				[_standardModifiers] call _addSpecial; 
			};
		};
		if(attkWave > 16 and attkWave<21) then {
			[_nonModified] call _addSpecial; 
			if(_random1Mod < 75) then {
				[_standardModifiers] call _addSpecial; 
			};
			if(_random2Mod < 25) then {
				[_standardModifiers] call _addSpecial; 
			};
		};
		if(attkWave > 20) then {
			[_nonModified] call _addSpecial;
			if(_random1Mod < attkWave*3) then {
				[_standardModifiers] call _addSpecial; 
			};
			if(_random2Mod < attkWave*2) then {
				[_standardModifiers] call _addSpecial;
			};
		};
	}
	else
	{
		if(attkWave > 20) then {
			if(random 100 < 25) then {
				[_standardModifiers] call _addSpecial;
			};
		};		
	};

    if (("SPECIAL_WAVES" call BIS_fnc_getParamValue) == 0 && {!_debugForced}) then {waveTypes = []};
    if (!_debugForced && {_vehicleWave >= 9999 || {attkWave < _vehicleWave}}) then {
        waveTypes = waveTypes - ["convoy", "paraDrop", "airstrike", "specMortarWave", "demineWave", "fpvOperator"];
    };
    if (_debugForced) then {waveTypes = [_debugSpecial]};
    defectorWave = "defectorWave" in waveTypes;
	if(debugNotification) then {
		["SpecialWarning",[waveTypes]] remoteExec ["BIS_fnc_showNotification", 0];
		};

	{
		_wave = _x;
		diag_log ["Selected wave %0", _wave];
		switch (_wave) do {
			case "specCivs":{
				diag_log _wave;
				specCivs = true;
				[_waveId] execVM "hostiles\civWave.sqf";
			};
			case "suicideWave":{
				diag_log _wave;
				suicideWave = true;
				[_waveId] execVM "hostiles\suicideWave.sqf";
				[_waveId] execVM "hostiles\suicideAudio.sqf";
			};
			case "specMortarWave":{
				diag_log _wave;
				specMortarWave = true;
				[_waveId] execVM "hostiles\specMortar.sqf";
			};
			case "demineWave":{
				diag_log _wave;
				demineWave = true;
				[_waveId] execVM "hostiles\droneFire.sqf";
			};
			case "defectorWave":{
				diag_log _wave;
				defectorWave = true;
			};
			case "fogWave":{	
				diag_log _wave;		
				60 setFog (0.2 + random 0.8);
				fogWave = true;
			};
			case "nightWave":{
				diag_log _wave;
				if (!nightWave) then {
                    currentTime = daytime;
                    skipTime (24 - currentTime);
                    nightWave = true;
                };
			};
            case "thunderstorm": {[_waveId] call bulwark_fnc_startStorm;};
            case "officerHunt": {[_waveId] call bulwark_fnc_startOfficerHunt;};
            case "fpvOperator": {[_waveId] call bulwark_fnc_startFpv;};
            case "arty": {[_waveId] execVM "hostiles\shelling.sqf";};
            case "grad": {[_waveId] execVM "hostiles\gradSalvo.sqf";};
			case "convoy":{
				private _convoyJob = [_waveId] spawn {
                    params ["_waveId"];
					_pos = [([] call bulwark_fnc_spawnAnchor), BULWARK_RADIUS+100, BULWARK_RADIUS+300,20,0] call BIS_fnc_findSafePos;
					private _convoyCount = 1 max floor (_waveId / 3);
					diag_log format ["Bulwark vehicles: wave %1, special convoy trucks %2", _waveId, _convoyCount];
					for "_i" from 1 to _convoyCount do {
						if !([_waveId] call bulwark_fnc_waveActive) exitWith {};
                        [[_pos], "hostiles\spawnUaz.sqf"] call bulwark_fnc_queueHostiles;
						sleep 1;  
					};
				};
                BW_SPAWN_JOBS pushBack _convoyJob;
			};
			case "paraDrop":{
				diag_log _wave;
				[[_waveId], "hostiles\ParaDropNew.sqf"] call bulwark_fnc_queueHostiles;
			};
			case "airstrike":{
				[[_waveId], "hostiles\airStrike.sqf"] call bulwark_fnc_queueHostiles;
			};
			case "encampment":{
				[[_waveId], "hostiles\createEmplacement.sqf"] call bulwark_fnc_queueHostiles;
			};
			default {
				["SpecialWarning",["Unknown wave type %0", _wave]] remoteExec ["BIS_fnc_showNotification", 0];
			};
		};
	} forEach waveTypes;

    // One snapshot replaces separate whole-world vehicle-type queries.
    {
        if (!alive _x && {_x isKindOf "LandVehicle" || {_x isKindOf "Air"}}) then {
            deleteVehicle _x;
        };
    } forEach vehicles;

	// Spawn
	_createHostiles = [[], "hostiles\createWave.sqf"] call bulwark_fnc_queueHostiles;
    if (missionExtract) exitWith {};

	if (attkWave > 1) then { //if first wave give player extra time before spawning enemies
		{deleteMarker _x} foreach lootDebugMarkers;
		[] call loot_fnc_cleanup;
		_spawnLoot = execVM "loot\spawnLoot.sqf";
		waitUntil {sleep 0.1; scriptDone _spawnLoot || {missionExtract}};
	};
