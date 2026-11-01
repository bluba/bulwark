// Registered finite producer: pending purchases keep the wave alive.
params ["_wave","_plan","_defector"];
private _side = if (_defector) then {resistance} else {east};
private _entries = _plan get "entries";
private _outcomes = [];
_plan set ["outcomes",_outcomes];
diag_log format ["BW vehicle plan wave=%1 budget=%2 unused=%3 entries=%4",_wave,_plan get "budget",_plan get "unused",_entries];
private _register = {
 params ["_unit","_points"];
 _unit setVariable ["killPointMulti",_points]; _unit setVariable ["points",[]];
 _unit addEventHandler ["Hit",killPoints_fnc_hit]; _unit addEventHandler ["Killed",killPoints_fnc_killed];
 (waveUnits select 0) pushBackUnique _unit;
};
private _initial = time + 15 + random 10;
waitUntil {sleep 0.5; time >= _initial || {!([_wave] call bulwark_fnc_waveActive)}};
{
 private _entry = _x;
 _entry params ["_class","_cost","_offset","_role","_cargoCount"];
 private _record = [_forEachIndex,_class,_cost,"waiting"];
 _outcomes pushBack _record;
 if !([_wave] call bulwark_fnc_waveActive) then {
  _record set [3,"cancelled"];
 } else {
  private _deadline = time + 180;
  private _age = _wave - ("ARMOUR_START_WAVE" call BIS_fnc_getParamValue);
  private _admitted = false;
  waitUntil {
   private _active = vehicles select {alive _x && {_x getVariable ["bw_regularWave",-1] == _wave} && {({alive _x} count crew _x) > 0}};
   private _heavy = _active findIf {(_x getVariable ["bw_ticketRole",""]) in ["heavy","combatAir"]};
   _admitted = count _active < (if (_age < 3) then {1} else {2}) &&
    {!(_role in ["heavy","combatAir"]) || {_age >= 14} || {_heavy < 0}};
   if (!_admitted) then {sleep 1};
   _admitted || {time >= _deadline} || {!([_wave] call bulwark_fnc_waveActive)}
  };
  if (!_admitted || {time >= _deadline} || {!([_wave] call bulwark_fnc_waveActive)}) then {
   _record set [3,"cancelled"];
  } else {
   _record set [3,"spawning"];
   private _air = _role in ["combatAir","transportAir"];
   private _anchor = [] call bulwark_fnc_spawnAnchor;
   private _position = [_anchor, BULWARK_RADIUS + (if (_air) then {700} else {100}), BULWARK_RADIUS + (if (_air) then {1000} else {300}),10,0] call BIS_fnc_findSafePos;
   if (_air) then {_position set [2,150]};
   private _result = [[_position,_position getDir _anchor,_class,_side],"vehicle",_wave,false,objNull,_deadline] call bulwark_fnc_spawnLimited;
   _result params ["_vehicle","_crew","_group"];
   if (isNull _vehicle) then {
    _record set [3,"failed"];
   } else {
    _record set [3,"deployed"];
    BW_VEHICLE_LAST = _class;
    _vehicle setVariable ["bw_regularWave",_wave];
    _vehicle setVariable ["bw_ticketRole",_role];
    _vehicle setVariable ["aiMode","NonCQB"];
    private _points = if (_role in ["armour","heavy"]) then {HOSTILE_ARMOUR_POINT_SCORE} else {HOSTILE_CAR_POINT_SCORE};
    {[_x,_points] call _register; _x setVariable ["aiMode","NonCQB"]} forEach _crew;
    if (!isNil "mainZeus") then {mainZeus addCuratorEditableObjects [[_vehicle],true]};
    if (_cargoCount == 0) then {
     _vehicle setVariable ["lambs_danger_disableAI",nil];
     [_vehicle,if (_air) then {2000} else {1000}] spawn lambs_wp_fnc_taskRush;
    } else {
     _vehicle setVariable ["bw_scriptedTransport",true,true];
     _group setVariable ["bw_scriptedMovement",true,true];
     _group setBehaviour "CARELESS";
     if (_air) then {_vehicle flyInHeight 150};
     private _pool = (if (_defector) then {DEFECTOR_INF} else {HOSTILE_LEVEL_2}) select {isClass (configFile >> "CfgVehicles" >> _x)};
     private _troops = createGroup [_side,true];
     _troops setVariable ["bw_scriptedMovement",true,true];
     if !(_pool isEqualTo []) then {
      for "_i" from 1 to _cargoCount do {
       private _unit = [[_troops,[selectRandom _pool,_position,[],0,"NONE"]],"unit",_wave,false,_vehicle,_deadline] call bulwark_fnc_spawnLimited;
       if (isNull _unit) exitWith {};
       [_unit,2] call _register;
       _unit moveInCargo _vehicle;
       if (_air) then {removeBackpack _unit; _unit addBackpack "B_Parachute"};
      };
     };
     private _wp = _group addWaypoint [_anchor,0]; _wp setWaypointSpeed "FULL";
     private _delivery = time + 120;
     waitUntil {sleep 1; !alive _vehicle || {_vehicle distance2D _anchor < 150} || {time >= _delivery} || {!([_wave] call bulwark_fnc_waveActive)}};
     if ([_wave] call bulwark_fnc_waveActive) then {
      {
       if (_air && {vehicle _x != _x}) then {moveOut _x; _x action ["OpenParachute",_x]} else {unassignVehicle _x; moveOut _x};
       _x setVariable ["aiMode","rush"];
      } forEach units _troops;
      _troops setVariable ["bw_scriptedMovement",false,true];
      [_troops,_wave] call bulwark_fnc_controlEnemyGroup;
     } else { {deleteVehicle _x} forEach units _troops; };
     if (units _troops isEqualTo []) then {deleteGroup _troops};
     // The delivery is finite; remove the carrier and its crew after unloading.
     {deleteVehicle _x} forEach _crew; deleteVehicle _vehicle; deleteGroup _group;
     _record set [3,"completed"];
    };
   };
  };
  diag_log format ["BW vehicle purchase wave=%1 result=%2",_wave,_record];
  private _next = time + 25;
  waitUntil {sleep 0.5; time >= _next || {!([_wave] call bulwark_fnc_waveActive)}};
 };
} forEach _entries;
