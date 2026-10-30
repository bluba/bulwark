private ["_opforSide", "_unitClasses", "_armorClasses", "_carClasses", "_heliClasses", "_hosSkill", "_randVar", "_carCrew", "_unitArray"];
private _wave = attkWave;
/**
*  spawnVehicle
*
*  Creates a single vehicle in a random location
*
*  Domain: Server
**/
_armorClasses = HOSTILE_ARMOUR;
_opforSide = EAST;
if(defectorWave) then {
	_armorClasses = DEFECTOR_ARMOR;
	_opforSide = RESISTANCE;
};

_armorClasses = _armorClasses select {isClass (configFile >> "CfgVehicles" >> _x)};
if (_armorClasses isEqualTo []) exitWith {diag_log "Bulwark: no valid vehicle classes"};
for "_i" from 1 to (ArmourCount) do {
        if !([_wave] call bulwark_fnc_waveActive) exitWith {};
	_randVar = random 100;
	_location = [([] call bulwark_fnc_spawnAnchor), BULWARK_RADIUS+50, BULWARK_RADIUS + 100,10,0] call BIS_fnc_findSafePos;
	_roads = _location nearRoads 100;
	_spawnLoc = _location;
	if(count _roads >0) then {
		_dist = 99999;
		{
			_nDist = _location distance2D getPos _x;
			if(_nDist<_dist) then{
				_dist = _nDist;
				_spawnLoc = getPos _x;
			};
		} forEach _roads;
	};
	_foundVeh = selectRandom _armorClasses;
	_createdVehFnc = [[_spawnLoc, 0, _foundVeh, _opforSide], "vehicle", _wave, false] call bulwark_fnc_spawnLimited;
    if (isNull (_createdVehFnc select 0)) exitWith {};
	
	if (_randVar<80) then {
				_createdVehFnc select 0 setVariable ["lambs_danger_disableAI", nil];
				[_createdVehFnc SELECT 0, 1000] spawn lambs_wp_fnc_taskCreep;
			}
			else
			{
				_createdVehFnc select 0 setVariable ["lambs_danger_disableAI", nil];
				[_createdVehFnc SELECT 0, 1000] spawn lambs_wp_fnc_taskRush;

			};
		_createdVehFnc select 0  setVariable ["aiMode","NonCQB"]; 

	/**
	_createdVehFnc select 0 doMove (getPos (selectRandom playableUnits));
	[_createdVehFnc select 0, (getPos (selectRandom playableUnits)), false] call lambs_wp_fnc_taskAssault;
	**/
	mainZeus addCuratorEditableObjects [[_createdVehFnc select 0], true];
	_tankcrew = fullCrew (_createdVehFnc select 0);
	{
		_x select 0 addEventHandler ["Hit", killPoints_fnc_hit];
		_x select 0 addEventHandler ["Killed", killPoints_fnc_killed];
		_x select 0 setVariable ["killPointMulti", HOSTILE_ARMOUR_POINT_SCORE];
		_unitArray = waveUnits select 0;
		_unitArray append [_x select 0];
		_x select 0  setVariable ["aiMode","NonCQB"]; 
		


	} forEach _tankcrew;
};
