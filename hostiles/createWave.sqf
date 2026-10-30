waveSpawned = true;
/**
*  createWave
*
*  Creates all the hostiles for the given round
*
*  Domain: Server
**/

_armourStartWave = "ARMOUR_START_WAVE" call BIS_fnc_getParamValue;
_allSpawnTest= false;
private _vehiclesEnabled = _armourStartWave < 9999 && {!([attkWave] call bulwark_fnc_debugForced)};

if(_vehiclesEnabled && {attkWave >=  (_armourStartWave + 5) && random 100< attkWave + ( (floor (attkWave/2) ) *5)} || _allSpawnTest) then{
	ArmourCount = floor (attkWave / 20)+1;
	ArmourCount = ArmourCount + floor(random (floor ((playersNumber west)/ 4)+1));
	_spwnVec = execVM "hostiles\spawnVehicle.sqf";
	waitUntil {scriptDone _spwnVec};
};

if(_vehiclesEnabled && {attkWave >=  _armourStartWave && random 100< attkWave + ( (floor (attkWave/1) ) *5)} || _allSpawnTest) then{
	carCount = floor (attkWave / 10)+2;
	carCount = carCount + floor(random (floor ((playersNumber west)/ 2)+1));
	_spwnVec = execVM "hostiles\spawnCar.sqf";
	waitUntil {scriptDone _spwnVec};
};

if(_vehiclesEnabled && {attkWave >=  _armourStartWave && random 100< attkWave + ( (floor (attkWave/2) ) *5)} || _allSpawnTest) then{
	heliCount = floor (attkWave / 10)+1;
	helicount = heliCount + floor(random (floor ((playersNumber west)/ 3)+1));
	_spwnVec = execVM "hostiles\spawnHeli.sqf";
	waitUntil {scriptDone _spwnVec};
};

try {
	if(_vehiclesEnabled && {attkWave >=  _armourStartWave && ((random 100)<(25+attkWave*2))} || _allSpawnTest) then{
		for "_i" from 0 to random((floor (attkWave/10)))+1  do { 
			[[([] call bulwark_fnc_spawnAnchor) , "RHS_Mi8mt_Cargo_vvsc", east, configNull], "hostiles\KillTeam.sqf"] call bulwark_fnc_queueHostiles;
		};
	};
}
catch {
	hint str _exception
};

try {
	if (_vehiclesEnabled && {attkWave >= _armourStartWave && {random 100 < 30 + attkWave}}) then {
		for "_i" from 0 to random (floor (attkWave/9))+1 do {
			[[[([] call bulwark_fnc_spawnAnchor) , BULWARK_RADIUS+100, BULWARK_RADIUS+300,20,0] call BIS_fnc_findSafePos ], "hostiles\spawnUaz.sqf"] call bulwark_fnc_queueHostiles;
		}
	}
}
catch {
	hint str _exception
};

_noOfPlayers = 1 max floor ((playersNumber west) * HOSTILE_TEAM_MULTIPLIER);
_multiplierBase = HOSTILE_MULTIPLIER;

if (attkWave <= 2) then {
	_multiplierBase = 1;
};

_levelMultiplier = HOSTILE_LEVEL_1_POINT_SCORE;
_hostileLevel = HOSTILE_LEVEL_1;

if (attkWave>6) then {
	_levelMultiplier = HOSTILE_LEVEL_2_POINT_SCORE;
	_hostileLevel = HOSTILE_LEVEL_1 + HOSTILE_LEVEL_2;
};

if (attkWave>10) then {
	_levelMultiplier = HOSTILE_LEVEL_2_POINT_SCORE;
	_hostileLevel = HOSTILE_LEVEL_2;
};

if (attkWave>14) then {
	_levelMultiplier = HOSTILE_LEVEL_3_POINT_SCORE;
	_hostileLevel = HOSTILE_LEVEL_2 + HOSTILE_LEVEL_3;
};

if (attkWave>18) then {
	_levelMultiplier = HOSTILE_LEVEL_3_POINT_SCORE;
	_hostileLevel = HOSTILE_LEVEL_3;
};

expected_enemies = (floor (attkWave * _multiplierBase * _noOfPlayers));
diag_log ["Hostile level %0",_hostileLevel];

BW_INFANTRY_REMAINING = expected_enemies;
waveSpawned = true;
_script = [_hostileLevel, attkWave, expected_enemies, _levelMultiplier ] execVM "hostiles\spawnSquad.sqf";
waitUntil {sleep 0.2; scriptDone _script};
BW_INFANTRY_REMAINING = 0;

waveSpawned = true;
