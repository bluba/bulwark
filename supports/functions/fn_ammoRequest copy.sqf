/**
*  fn_paraTroop
*
*  Calls VTOL to drop a group of paratroopers on the specified location
*
*  Domain: Server
**/
params ["_player", "_targetPos"];

if (count _targetPos == 0) then {
  [_player, "paraDrop"] remoteExec ["BIS_fnc_addCommMenuItem", _player]; //refund the support if looking at sky when activated
}else{
  _angle = round random 180;
  _height = 300;
  _offsX = 0;
  _offsY = 1000;
  _pointX = _offsX*(cos _angle) - _offsY*(sin _angle);
  _pointY = _offsX*(sin _angle) + _offsY*(cos _angle);

  _dropStart  = _targetPos vectorAdd [_pointX, _pointY, _height];
  _dropTarget = [(_targetPos select 0), (_targetPos select 1), 200];
  _dropEnd    = _targetPos vectorAdd [-_pointX*2, -_pointY*2, _height];;

  _targetSmoker = "SmokeShellOrange" createVehicle (_targetPos vectorAdd [0,0,0.3]);

  _agSpawn = [_dropStart, 0, "PSZ_PL_WDL20_Mi17AE_MEDEVAC", WEST] call bis_fnc_spawnvehicle;
  _agVehicle = _agSpawn select 0;	//the aircraft
  _agCrew = _agSpawn select 1;	//the units that make up the crew
  _ag = _agSpawn select 2;	//the group
  {_x allowFleeing 0} forEach units _ag;
mainZeus addCuratorEditableObjects [[_agVehicle], true];
  _agVehicle flyInHeight 100;
  _agVehicle setpos [getposATL _agVehicle select 0, getposATL _agVehicle select 1, _height];

  _relDir = [_dropStart, _targetPos] call BIS_fnc_dirTo;
  _agVehicle setdir _relDir;

  paraTroopLatch = false;
 diag_log "move to drop target";
  _waypoint0 = _ag addwaypoint[_dropTarget, 0];
  _waypoint0 setwaypointtype "Move";
  _waypoint0 setWaypointCompletionRadius 5;
  _waypoint0 setWaypointStatements ["true", "paraTroopLatch = true;"];

   waitUntil {paraTroopLatch};
   diag_log "move to player";
   [_ag, 1] setWaypointSpeed "NORMAL";
  [_ag, 1] setWaypointCombatMode "RED";
  [_ag, 1] setWaypointBehaviour "CARELESS";
   paraTroopLatch = false;
  _dropTarget = [(_targetPos select 0), (_targetPos select 1), 0];
  _waypoint1 = _ag addwaypoint[_dropTarget, 0];
  _waypoint1 setwaypointtype "Move";
  _waypoint1 setWaypointCompletionRadius 1;
  _waypoint1 setWaypointStatements ["true", "paraTroopLatch = true;"];
  _agVehicle animateDoor ['Door_1_source', 1];
  waitUntil{paraTroopLatch};
  // Drop cargo
_playerCount = count playableUnits;

sleep 2;
[_agVehicle] spawn {
 _agVehicle= _this select 0;
_playerCount = count playableUnits;
_parachute = "B_Parachute_02_F" CreateVehicle [0,0,0];
_parachute setPos [getPos _agVehicle select 0, getPos _agVehicle select 1, (getPos _agVehicle select 2)-5];
_supplyBox = createVehicle ["Land_WoodenCrate_01_F", [0,0,0], [], 0, "CAN_COLLIDE"];
[_supplyBox, ["<t color='#00ff00'>" + "FILL AMMO", "supports\ammoDrop.sqf","",2,true,false,"true","true",4]] remoteExec ["addAction", 0, true];
_supplyBox attachTo [_parachute, [0,0,0]];
_supplyBox allowDamage false;
waitUntil {getpos _supplyBox select 2<4};
_smoker = "SmokeShellBlue" createVehicle (getpos _supplyBox vectorAdd [0,0,5]);
detach _supplyBox;};

sleep 2;
[_agVehicle] spawn {
  _agVehicle= _this select 0;
_playerCount = count playableUnits;
_parachute = "B_Parachute_02_F" CreateVehicle [0,0,0];
_parachute setPos [getPos _agVehicle select 0, getPos _agVehicle select 1, (getPos _agVehicle select 2)-5];
_supplyBox = createVehicle ["Land_WoodenCrate_01_F", [0,0,0], [], 0, "CAN_COLLIDE"];
[_supplyBox, ["<t color='#00ff00'>" + "FILL AMMO", "supports\ammoDrop.sqf","",2,true,false,"true","true",4]] remoteExec ["addAction", 0, true];
_supplyBox attachTo [_parachute, [0,0,0]];
_supplyBox allowDamage false;
waitUntil {getpos _supplyBox select 2<4};
_smoker = "SmokeShellBlue" createVehicle (getpos _supplyBox vectorAdd [0,0,5]);
detach _supplyBox;};

sleep 2;
[_agVehicle] spawn {
_agVehicle= _this select 0;
_parachute = "B_Parachute_02_F" CreateVehicle [0,0,0];
_parachute setPos [getPos _agVehicle select 0, getPos _agVehicle select 1, (getPos _agVehicle select 2)-5];
_supplyBox = createVehicle ["Land_WoodenCrate_01_F", [0,0,0], [], 0, "CAN_COLLIDE"];
[_supplyBox, ["<t color='#00ff00'>" + "FILL AMMO", "supports\ammoDrop.sqf","",2,true,false,"true","true",4]] remoteExec ["addAction", 0, true];
_supplyBox attachTo [_parachute, [0,0,0]];
_supplyBox allowDamage false;
waitUntil {getpos _supplyBox select 2<4};
_smoker = "SmokeShellBlue" createVehicle (getpos _supplyBox vectorAdd [0,0,5]);
detach _supplyBox;};

diag_log "move to end";
  _waypoint2 = _ag addwaypoint[_dropEnd, 0];
  _waypoint2 setwaypointtype "Move";

  [_ag, 1] setWaypointSpeed "FULL";
  [_ag, 1] setWaypointCombatMode "RED";
  [_ag, 1] setWaypointBehaviour "CARELESS";




  sleep 0.5;

  sleep 20;
  deleteVehicle _agVehicle;
  {deleteVehicle _x} foreach _agCrew;
};
