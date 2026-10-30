private ["_opforSide", "_unitClasses", "_armorClasses", "_carClasses", "_heliClasses", "_hosSkill", "_randVar", "_carCrew", "_unitArray"];
private _wave = attkWave;
_opforSide = EAST; 
_pPos = ([] call bulwark_fnc_spawnAnchor);

_location = _this select 0;
	_roads = _location nearRoads 500;
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
_spawnLoc = [_spawnLoc, 0, 50,7,0] call BIS_fnc_findSafePos;
_class = "RHS_Ural_Open_MSV_01";
if (!isClass (configFile >> "CfgVehicles" >> _class)) exitWith {};
_createdVehFnc = [[_spawnLoc, 0, _class, _opforSide], "vehicle", _wave, false] call bulwark_fnc_spawnLimited;  
    if (isNull (_createdVehFnc select 0)) exitWith {};
_vechicle = _createdVehFnc select 0;
_vechicle setVariable ["bw_scriptedTransport", true, true];
private _driverGroup = _createdVehFnc select 2;
_driverGroup setVariable ["bw_scriptedMovement", true, true]; 
_reldir = [getPos _vechicle, _pPos] call BIS_fnc_dirTo;
_vechicle setdir _reldir;
_vechicle setVariable ["lambs_danger_disableAI", nil];
// Transport movement is owned by this script, not a competing creep task.
private _driveWP = _driverGroup addWaypoint [_pPos, 0];
_driveWP setWaypointType "MOVE";
_driveWP setWaypointSpeed "FULL";
_vechicle  setVariable ["aiMode","NonCQB"];
_vechicle setVariable ["lambs_danger_disableAI", true];


mainZeus addCuratorEditableObjects [[_vechicle], true];

sleep 5;

if (!(alive _vechicle) || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {{deleteVehicle _x} forEach crew _vechicle; deleteVehicle _vechicle};


_cargoLimit = getNumber (configfile >> "CfgVehicles" >> _class >> "transportSoldier"); //units in cargo
_turretLimit = "getNumber (_x >> 'dontCreateAI') == 1" configClasses (configfile >> "CfgVehicles" >> _class >> "Turrets"); //not populated turret
_cargoLimit = _cargoLimit + (count _turretLimit); //cumulate values
		_grp = [[[0,0,0], _opforSide, ["rhs_vdv_sergeant","rhs_vdv_medic","rhs_vdv_arifleman","rhs_vdv_rifleman","rhs_vdv_rifleman","rhs_vdv_rifleman","rhs_vdv_rifleman","rhs_vdv_rifleman","rhs_vdv_rifleman","rhs_vdv_LAT"], [], [], [0.3, 0.3]], "group", _wave, false, _vechicle] call bulwark_fnc_spawnLimited; // Create team onboard, need to be done at the last time or enableDynamicSimulation will fail
if (isNull _grp || {!alive _vechicle} || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {
    {deleteVehicle _x} forEach units _grp;
    deleteGroup _grp;
    {deleteVehicle _x} forEach (_createdVehFnc select 1);
    deleteVehicle _vechicle;
    deleteGroup _driverGroup;
};
		_grp allowFleeing 0;
        {_x setVariable ["killPointMulti", 2, true]; _x setVariable ["points", []]; _x addEventHandler ["Hit", killPoints_fnc_hit]; _x addEventHandler ["Killed", killPoints_fnc_killed]; (waveUnits select 0) pushBackUnique _x} forEach units _grp; //not allowed to flee
		_grp deleteGroupWhenEmpty true; //Mark for auto deletion and enable Dynamic simulation
		_cargoCurrent = 0;
		{
			_cargoCurrent = _cargoCurrent + 1; //increment 
			if (_cargoCurrent > _cargoLimit-2) then { //cargo overflow
				deleteVehicle _x; //delete unit
			} else {
				_x moveInCargo _vechicle; //move in cargo
				_x assignAsCargo _vechicle; //assign as cargo
				[_x] call nss_fnc_AIskill; //set skills
			};
			_x  setVariable ["aiMode","NonCQB"];
			_x setVariable ["lambs_danger_disableAI", true];
			mainZeus addCuratorEditableObjects [[_x], true];
		} forEach (units _grp); //units loop


private _deadline = time + 180;
waitUntil {sleep 1; _vechicle distance2D _pPos < 100 || {!alive _vechicle} || {damage _vechicle > 0.1} || {time >= _deadline} || {!([_wave] call bulwark_fnc_waveActive)}};

{ //disembark units if heli still alive

			//[format["HeliSupportLanding.sqf: Unload unit, altitude:%1m", _tmpAlt]] call nss_fnc_debugOutput; //debug
		
				
				_x setVariable ["lambs_danger_disableAI", nil];
				_x setVariable ["aiMode", "rush"];
				_x leaveVehicle _vechicle;

		} forEach (units _grp);
_grp setVariable ["bw_scriptedMovement", false, true];
if ([_wave] call bulwark_fnc_waveActive) then {[_grp, _wave] call bulwark_fnc_controlEnemyGroup};
private _leaveAt = time + 30;
waitUntil {sleep 0.5; time >= _leaveAt || {!([_wave] call bulwark_fnc_waveActive)}};
if !([_wave] call bulwark_fnc_waveActive) exitWith {
    {deleteVehicle _x} forEach (_createdVehFnc select 1);
    deleteVehicle _vechicle;
    deleteGroup _driverGroup;
};
_vechicle setVariable ["lambs_danger_disableAI", true];
[_vechicle, true, true] call lambs_wp_fnc_taskReset;
 _vechicle doMove _spawnLoc;

private _cleanupAt = time + 60;
waitUntil {sleep 0.5; time >= _cleanupAt || {!([_wave] call bulwark_fnc_waveActive)}};
if !([_wave] call bulwark_fnc_waveActive) exitWith {
    {deleteVehicle _x} forEach (_createdVehFnc select 1);
    deleteVehicle _vechicle;
    deleteGroup _driverGroup;
};
_vechicle setDamage 1;
