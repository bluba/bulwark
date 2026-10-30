private ["_opforSide", "_unitClasses", "_armorClasses", "_carClasses", "_heliClasses", "_hosSkill", "_randVar", "_carCrew", "_unitArray"];
private _wave = attkWave;
/**
*  spawnSquad
*
*  Creates a squad of units in a random location
*
*  Domain: Server
**/
diag_log "--------------spawnSquad---------------";
_randWeapons = "RANDOM_WEAPONS" call BIS_fnc_getParamValue;
_opforSide = EAST;
_unitClasses = _this select 0;
private _suicideClasses = HOSTILE_SUICIDE select {isClass (configFile >> "CfgVehicles" >> _x)};
if (defectorWave) then { //determine if defect wave and spawn from List defined in EditMe.sqf
	_unitClasses = DEFECTOR_INF;
	_opforSide = RESISTANCE;
} ;

_attackWave  = _this select 1;
_unitCount   = _this select 2;
_unitClasses = _unitClasses select {isClass (configFile >> "CfgVehicles" >> _x)};
if (_unitClasses isEqualTo []) exitWith {diag_log "Bulwark: no valid infantry classes"};
_killPointMulti  = _this select 3;

_hosSkill = 0.05;
if (_attackWave < 5) then { //determine AI skill based on Wave
	_hosSkill = 0.05;
};
if (_attackWave < 10 && _attackWave >= 5) then {
	_hosSkill = 0.075;
};
if (_attackWave < 15 && _attackWave >= 10) then {
	_hosSkill = 0.1;
};
if (_attackWave < 20 && _attackWave >= 15) then {
	_hosSkill = 0.15;
};
if (_attackWave < 25 && _attackWave >= 20) then {
	_hosSkill = 0.4;
};
if (_attackWave < 30 && _attackWave >= 25) then {
	_hosSkill = 0.5;
};
if (_attackWave >= 30) then {
	_hosSkill = 1;
};

sleep 0.5;


diag_log _attackWave;
if (_unitCount<10 || suicideWave) then {
	diag_log "SoloSpawn";
	for ("_i") from 1 to _unitCount do {
        if !([_wave] call bulwark_fnc_waveActive) exitWith {};
		_location = [([] call bulwark_fnc_spawnAnchor), BULWARK_RADIUS + 30, BULWARK_RADIUS + 150,1,0] call BIS_fnc_findSafePos;
		_unitClass = "";
		if( suicideWave) then {
			if (_suicideClasses isEqualTo []) exitWith {};
            _unitClass = selectRandom _suicideClasses;
		} 
		else{
			_unitClass = selectRandom _unitClasses;
		};
		if (!isClass (configFile >> "CfgVehicles" >> _unitClass)) exitWith {diag_log format ["Bulwark: invalid infantry class %1", _unitClass]};
        _attGroupBand = createGroup [_opforSide, true];
        _unit = objNull;
		_unit = [[_attGroupBand, [_unitClass, _location, [], 0.5, "FORM"]], "unit", _wave, true] call bulwark_fnc_spawnLimited;
		sleep 0.3;
		if (isNull _unit) exitWith {deleteGroup _attGroupBand; diag_log format ["Bulwark: cannot spawn %1", _unitClass]};

		BW_INFANTRY_REMAINING = 0 max (BW_INFANTRY_REMAINING - 1);
		[_unit] join _attGroupBand;	

		_unit setUnitAbility _hosSkill; //todo https://community.bistudio.com/wiki/CfgAISkill
		_unit setSkill ["aimingAccuracy", _hosSkill];
		_unit setSkill ["aimingSpeed", (_hosSkill * 0.75)];
		_unit setSkill ["aimingShake", _hosSkill];
		_unit setSkill ["spotTime", 0.05];
		_unit addEventHandler ["Hit", killPoints_fnc_hit];
		_unit addEventHandler ["Killed", killPoints_fnc_killed];
		removeAllAssignedItems _unit;
		_unit setVariable ["points", []];
		_unit setVariable ["killPointMulti", _killPointMulti];
		
		
		if (_randWeapons == 1) then {
			_unitPrimaryWeap = primaryWeapon _unit;
			_primaryAmmoTpyes = getArray (configFile >> "CfgWeapons" >> _unitPrimaryWeap >> "magazines");
			{
				if (_x in _primaryAmmoTpyes) then {
					_unit removeMagazineGlobal _x;
				};
			}forEach magazines _unit;
			_unitPrimaryToAdd = selectRandom List_Primaries;
			_unitMagToAdd = selectRandom getArray (configFile >> "CfgWeapons" >> _unitPrimaryToAdd >> "magazines");
			_unit addWeaponGlobal _unitPrimaryToAdd;
			_unit addPrimaryWeaponItem _unitMagToAdd;
			_unit addMagazine _unitMagToAdd;
			_unit addMagazine _unitMagToAdd;
			_unit addMagazine _unitMagToAdd;
			_unit selectWeapon _unitPrimaryToAdd;
		};

		if(_attackWave <= PISTOL_HOSTILES) then {
			removeAllWeapons _unit;
			_unit addMagazine "16Rnd_9x21_Mag";
			_unit addMagazine "16Rnd_9x21_Mag";
			_unit addWeapon "hgun_P07_F";
			if ((floor random 4) == 1) then {
				_unit additem "FirstAidKit";
			};
		};

		if (suicideWave) then {
			removeAllWeapons _unit;
			_unit setVariable ["bw_suicideBomber", true, true];
            _unit addEventHandler ["Killed", Hostiles_fnc_suiExplode];
		};

		if (demineWave && (floor random 2 == 0) && droneCount < 15) then {
			droneCount = droneCount + 1;
			_aicrew = createGroup [_opforSide, true];
			_drone = [[_location, 50, "C_IDAP_UAV_06_antimine_F", _aicrew], "vehicle", _wave, false] call bulwark_fnc_spawnLimited;
			droneSquad pushback _aicrew;
            (waveUnits select 0) append [(_drone select 0)];
            { (waveUnits select 0) pushBack _x; _x setVariable ["aiMode", "NonCQB"]; _x setVariable ["points", []]; } forEach (_drone select 1);
			_wp1 = _aicrew addWaypoint [position bulwarkBox, 0];
			_wp1 setWaypointType "SAD";
			_leadah = leader _aicrew;
			_leadah flyInHeight 30;
			_leadah setSkill 1;
			sleep 0.5;
			mainZeus addCuratorEditableObjects [[_drone select 0], true];
			_leadah addEventHandler ["Hit", killPoints_fnc_hit];
			_leadah addEventHandler ["Killed", {
				params ["_unit", "_killer", "_instigator", "_useEffects"];
				call killPoints_fnc_killed;
				_scriptedCharge = "HandGrenade" createVehicle (getPos _unit);
				_scriptedCharge setdamage 1;
				deleteVehicle _unit;
			}];
			_leadah setVariable ["killPointMulti", HOSTILE_CAR_POINT_SCORE];
		};
		mainZeus addCuratorEditableObjects [[_unit], true];
		_unitArray = waveUnits select 0;
		_unitArray append [_unit];
		
		diag_log _unit;
		
		_attGroupBand setVariable ["bw_baseMode", "rush", true];
        _unit setVariable ["aiMode", "rush", true];
        [_attGroupBand, _wave] call bulwark_fnc_controlEnemyGroup;
	};
}
else
{	
	diag_log "TeamSpawn";
	_spawnedUnits = 0;
	while {_spawnedUnits < _unitCount && {[_wave] call bulwark_fnc_waveActive}} do {
		private _teamCount = (1 + floor random 5) min (_unitCount - _spawnedUnits);
		diag_log _teamCount;
		_location = [([] call bulwark_fnc_spawnAnchor), BULWARK_RADIUS + 30, BULWARK_RADIUS + 150,1,0] call BIS_fnc_findSafePos;

		_classes = [];
		for ("_i") from 1 to _teamCount do {
			_classes append [selectRandom _unitClasses];
		};


		_myGroup = [[_location, _opforSide, _classes,[],[],[],[],[],180], "group", _wave, true] call bulwark_fnc_spawnLimited;
		
		if (isNull _myGroup || {units _myGroup isEqualTo []}) exitWith {if (!isNull _myGroup) then {deleteGroup _myGroup}; diag_log "Bulwark: squad creation failed"};
        _attGroupBand = _myGroup;
        private _createdTeamCount = count units _myGroup;
        private _groupMode = if (random 100 < 34) then {"creep"} else {"rush"};
        _attGroupBand setVariable ["bw_baseMode", _groupMode, true];
        _attGroupBand deleteGroupWhenEmpty true;
		{
			_unit = _x;
			[_unit] join _attGroupBand;	
			_unit setUnitAbility _hosSkill; //todo https://community.bistudio.com/wiki/CfgAISkill
			_unit setSkill ["aimingAccuracy", _hosSkill];
			_unit setSkill ["aimingSpeed", (_hosSkill * 0.75)];
			_unit setSkill ["aimingShake", _hosSkill];
			_unit setSkill ["spotTime", 0.05];
			_unit addEventHandler ["Hit", killPoints_fnc_hit];
			_unit addEventHandler ["Killed", killPoints_fnc_killed];
			removeAllAssignedItems _unit;
			_unit setVariable ["points", []];
			_unit setVariable ["killPointMulti", _killPointMulti];
			
			
			if (_randWeapons == 1) then {
				_unitPrimaryWeap = primaryWeapon _unit;
				_primaryAmmoTpyes = getArray (configFile >> "CfgWeapons" >> _unitPrimaryWeap >> "magazines");
				{
					if (_x in _primaryAmmoTpyes) then {
						_unit removeMagazineGlobal _x;
					};
				}forEach magazines _unit;
				_unitPrimaryToAdd = selectRandom List_Primaries;
				_unitMagToAdd = selectRandom getArray (configFile >> "CfgWeapons" >> _unitPrimaryToAdd >> "magazines");
				_unit addWeaponGlobal _unitPrimaryToAdd;
				_unit addPrimaryWeaponItem _unitMagToAdd;
				_unit addMagazine _unitMagToAdd;
				_unit addMagazine _unitMagToAdd;
				_unit addMagazine _unitMagToAdd;
				_unit selectWeapon _unitPrimaryToAdd;
			};

			if(_attackWave <= PISTOL_HOSTILES) then {
				removeAllWeapons _unit;
				_unit addMagazine "16Rnd_9x21_Mag";
				_unit addMagazine "16Rnd_9x21_Mag";
				_unit addWeapon "hgun_P07_F";
				if ((floor random 4) == 1) then {
					_unit additem "FirstAidKit";
				};
			};

			if (suicideWave) then {
				removeAllWeapons _unit;
				_unit setVariable ["bw_suicideBomber", true, true];
            _unit addEventHandler ["Killed", Hostiles_fnc_suiExplode];
			};

			if (demineWave && (floor random 2 == 0) && droneCount < 15) then {
				droneCount = droneCount + 1;
				_aicrew = createGroup [_opforSide, true];
				_drone = [[_location, 50, "C_IDAP_UAV_06_antimine_F", _aicrew], "vehicle", _wave, false] call bulwark_fnc_spawnLimited;
				droneSquad pushback _aicrew;
            (waveUnits select 0) append [(_drone select 0)];
            { (waveUnits select 0) pushBack _x; _x setVariable ["aiMode", "NonCQB"]; _x setVariable ["points", []]; } forEach (_drone select 1);
				_wp1 = _aicrew addWaypoint [position bulwarkBox, 0];
				_wp1 setWaypointType "SAD";
				_leadah = leader _aicrew;
				_leadah flyInHeight 30;
				_leadah setSkill 1;
				sleep 0.5;
				mainZeus addCuratorEditableObjects [[_drone select 0], true];
				_leadah addEventHandler ["Hit", killPoints_fnc_hit];
				_leadah addEventHandler ["Killed", {
					params ["_unit", "_killer", "_instigator", "_useEffects"];
					call killPoints_fnc_killed;
					_scriptedCharge = "HandGrenade" createVehicle (getPos _unit);
					_scriptedCharge setdamage 1;
					deleteVehicle _unit;
				}];
				_leadah setVariable ["killPointMulti", HOSTILE_CAR_POINT_SCORE];
			};
			mainZeus addCuratorEditableObjects [[_unit], true];
			_unitArray = waveUnits select 0;
			_unitArray append [_unit];
			
			_unit setVariable ["aiMode", _groupMode, true];
			diag_log _unit;
			

		} foreach units _myGroup;
        [_attGroupBand, _wave] call bulwark_fnc_controlEnemyGroup;
		

		BW_INFANTRY_REMAINING = 0 max (BW_INFANTRY_REMAINING - _createdTeamCount);
        _spawnedUnits = _spawnedUnits + _createdTeamCount;
		diag_log "Spawned units";
		diag_log _spawnedUnits;
	};
};

